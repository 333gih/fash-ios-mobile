import Foundation
import Observation

@Observable
@MainActor
final class AppMaintenanceController {
    private static let persistedOnKey = "fash.app.maintenance.last"
    private static let persistedPhaseKey = "fash.app.maintenance.phase"
    private static let seenResumeKey = "fash.app.maintenance.seen_resume"

    private(set) var status: AppMaintenanceStatus
    private(set) var isReady: Bool = false
    private(set) var pendingResume: MaintenanceResumePresentation?
    var isMaintenance: Bool { status.isLocked }
    var isWarning: Bool { status.isWarning }

    private var sawRestrictedThisSession = false
    private let repository: AppStatusRepository

    init(repository: AppStatusRepository) {
        self.repository = repository
        self.status = Self.loadPersisted()
        if status.sawRestricted {
            sawRestrictedThisSession = true
        }
    }

    func apply(_ next: AppMaintenanceStatus) {
        let prev = status
        status = next
        isReady = true
        if next.sawRestricted {
            sawRestrictedThisSession = true
        }
        maybeQueueResume(prev: prev, next: next)
        UserDefaults.standard.set(next.isLocked, forKey: Self.persistedOnKey)
        UserDefaults.standard.set(next.phase, forKey: Self.persistedPhaseKey)
    }

    func dismissResumePresentation() {
        if let token = pendingResume?.updatedAtToken, !token.isEmpty {
            Self.markResumeSeen(token)
        }
        pendingResume = nil
    }

    func applyFromPushData(_ data: [String: String]) -> Bool {
        let type = (data["type"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard type == "app.maintenance" || type == "app.status.changed" || type == "admin.app_maintenance" else {
            return false
        }
        var merged: [String: Any] = [:]
        for (k, v) in data { merged[k] = v }
        apply(AppMaintenanceStatus.parse(from: merged))
        return true
    }

    func refreshNow() async {
        do {
            apply(try await repository.fetch())
        } catch {
            isReady = true
            if !sawRestrictedThisSession && !status.sawRestricted {
                apply(.open)
            }
        }
    }

    func displayTitle(defaultTitle: String) -> String {
        if let title = status.title, !title.isEmpty { return title }
        return defaultTitle
    }

    func displayMessage(defaultMessage: String) -> String {
        if let message = status.message, !message.isEmpty { return message }
        return defaultMessage
    }

    private func maybeQueueResume(prev: AppMaintenanceStatus, next: AppMaintenanceStatus) {
        guard sawRestrictedThisSession else { return }
        guard prev.sawRestricted, !next.sawRestricted else { return }
        guard let moment = next.resumeMoment?.trimmingCharacters(in: .whitespacesAndNewlines), !moment.isEmpty else {
            return
        }
        let token = (next.updatedAtIso ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty, !Self.hasSeenResume(token) else { return }
        pendingResume = MaintenanceResumePresentation(
            moment: moment,
            releaseNotesTitle: next.releaseNotesTitle,
            releaseNotes: next.releaseNotes,
            updatedAtToken: token
        )
    }

    private static func hasSeenResume(_ token: String) -> Bool {
        UserDefaults.standard.string(forKey: seenResumeKey) == token
    }

    private static func markResumeSeen(_ token: String) {
        UserDefaults.standard.set(token, forKey: seenResumeKey)
    }

    private static func loadPersisted() -> AppMaintenanceStatus {
        let phase = UserDefaults.standard.string(forKey: persistedPhaseKey) ?? ""
        let locked = UserDefaults.standard.bool(forKey: persistedOnKey) ||
            phase.caseInsensitiveCompare("maintenance") == .orderedSame
        if locked {
            return AppMaintenanceStatus(
                maintenance: true,
                phase: "maintenance",
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
        }
        if phase.caseInsensitiveCompare("warning") == .orderedSame {
            return AppMaintenanceStatus(
                maintenance: false,
                phase: "warning",
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
        }
        return .open
    }
}
