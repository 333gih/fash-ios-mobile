import Foundation

struct AppMaintenanceStatus: Equatable {
    var maintenance: Bool
    var title: String?
    var message: String?

    static let open = AppMaintenanceStatus(maintenance: false, title: nil, message: nil)

    static func parse(from raw: [String: Any]) -> AppMaintenanceStatus {
        let payload = (raw["data"] as? [String: Any]) ?? raw
        let maintenance = boolValue(payload["maintenance"]) || boolValue(payload["enabled"])
        return AppMaintenanceStatus(
            maintenance: maintenance,
            title: stringValue(payload["title"]),
            message: stringValue(payload["message"])
        )
    }

    static func parse(jsonText: String) -> AppMaintenanceStatus? {
        guard let data = jsonText.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return parse(from: root)
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
