import Foundation

struct AppMaintenanceStatus: Equatable {
    var maintenance: Bool
    var phase: String
    var mode: String
    var startsAtIso: String?
    var countdownSeconds: Int
    var title: String?
    var message: String?
    var updatedAtIso: String?
    var resumeMoment: String?
    var releaseNotesTitle: String?
    var releaseNotes: String?

    var isLocked: Bool { maintenance || phase.caseInsensitiveCompare("maintenance") == .orderedSame }
    var isWarning: Bool { !isLocked && phase.caseInsensitiveCompare("warning") == .orderedSame }
    var sawRestricted: Bool { isWarning || isLocked }

    static let open = AppMaintenanceStatus(
        maintenance: false,
        phase: "open",
        mode: "none",
        startsAtIso: nil,
        countdownSeconds: 0,
        title: nil,
        message: nil,
        updatedAtIso: nil,
        resumeMoment: nil,
        releaseNotesTitle: nil,
        releaseNotes: nil
    )

    func remainingSeconds(now: Date = Date()) -> Int {
        if let iso = startsAtIso?.trimmingCharacters(in: .whitespacesAndNewlines), !iso.isEmpty,
           let date = Self.parseISO(iso) {
            return max(0, Int(date.timeIntervalSince(now)))
        }
        return max(0, countdownSeconds)
    }

    func pollIntervalNanoseconds() -> UInt64 {
        if isWarning { return 1_000_000_000 }
        if isLocked { return 5_000_000_000 }
        return 8_000_000_000
    }

    static func parse(from raw: [String: Any]) -> AppMaintenanceStatus {
        let payload = (raw["data"] as? [String: Any]) ?? raw
        let phaseRaw = stringValue(payload["phase"]) ?? ""
        let locked = boolValue(payload["maintenance"]) || boolValue(payload["enabled"]) ||
            phaseRaw.caseInsensitiveCompare("maintenance") == .orderedSame
        let phase: String
        if locked {
            phase = "maintenance"
        } else if phaseRaw.caseInsensitiveCompare("warning") == .orderedSame {
            phase = "warning"
        } else {
            phase = phaseRaw.isEmpty ? "open" : phaseRaw
        }
        let countdown: Int
        if let n = payload["countdown_seconds"] as? Int {
            countdown = n
        } else if let n = payload["countdown_seconds"] as? NSNumber {
            countdown = n.intValue
        } else {
            countdown = 0
        }
        return AppMaintenanceStatus(
            maintenance: locked,
            phase: phase,
            mode: stringValue(payload["mode"]) ?? "none",
            startsAtIso: stringValue(payload["starts_at"]),
            countdownSeconds: countdown,
            title: stringValue(payload["title"]),
            message: stringValue(payload["message"]),
            updatedAtIso: stringValue(payload["updated_at"]),
            resumeMoment: stringValue(payload["resume_moment"]),
            releaseNotesTitle: stringValue(payload["release_notes_title"]),
            releaseNotes: stringValue(payload["release_notes"])
        )
    }

    static func parse(jsonText: String) -> AppMaintenanceStatus? {
        guard let data = jsonText.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return parse(from: root)
    }

    private static func parseISO(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: raw)
    }
}

private func boolValue(_ raw: Any?) -> Bool {
    if let b = raw as? Bool { return b }
    if let n = raw as? NSNumber { return n.boolValue }
    if let s = raw as? String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return t == "true" || t == "1" || t == "yes"
    }
    return false
}

private func stringValue(_ raw: Any?) -> String? {
    guard let s = raw as? String else { return nil }
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
    return t.isEmpty ? nil : t
}

/// Public kill-switch: `GET /api/v1/app/status` with a plain session (no JWT / attestation).
final class AppStatusRepository {
    func fetch() async throws -> AppMaintenanceStatus {
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in AppEnvironment.coreApiCandidateURLs("api/v1/app/status") {
            do {
                return try await fetch(urlString: urlString)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private func fetch(urlString: String) async throws -> AppMaintenanceStatus {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 8
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Fash-iOS/1.0.3", forHTTPHeaderField: "User-Agent")
        req.setValue(AppLocale.coreApiPathSegment(), forHTTPHeaderField: "Accept-Language")
        req.setValue(AppLocale.coreApiPathSegment(), forHTTPHeaderField: "X-Fash-Lang")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw CoreServiceHttpException(
                statusCode: http.statusCode,
                message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
            )
        }
        let root = try RepositoryHttp.jsonObject(data)
        return AppMaintenanceStatus.parse(from: root)
    }
}
