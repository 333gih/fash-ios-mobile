import Foundation
import Network
import Observation

@Observable
@MainActor
final class AppMaintenanceController {
    static let fcmTopic = AppStatusPush.fcmTopic

    private static let persistedOnKey = "fash.app.maintenance.last"
    private static let persistedPhaseKey = "fash.app.maintenance.phase"
    private static let persistedStartsAtKey = "fash.app.maintenance.starts_at"
    private static let persistedCountdownKey = "fash.app.maintenance.countdown"
    private static let persistedTitleKey = "fash.app.maintenance.title"
    private static let persistedMessageKey = "fash.app.maintenance.message"
    private static let seenResumeKey = "fash.app.maintenance.seen_resume"

    private(set) var status: AppMaintenanceStatus
    /// Persisted snapshot is enough to paint the first frame — do not block Home on GET /app/status.
    private(set) var isReady: Bool = true
    private(set) var pendingResume: MaintenanceResumePresentation?
    var isMaintenance: Bool { status.isEffectivelyLocked() }
    var isWarning: Bool { status.isWarning && !status.isEffectivelyLocked() }

    private var sawRestrictedThisSession = false
    private let repository: AppStatusRepository
    private var pathMonitor: NWPathMonitor?
    private var lastPathSatisfied: Bool?

    init(repository: AppStatusRepository) {
        self.repository = repository
        self.status = Self.loadPersisted()
        if status.sawRestricted {
            sawRestrictedThisSession = true
        }
        startConnectivityRefresh()
    }

    func apply(_ next: AppMaintenanceStatus) {
        applyInternal(next, fromNetwork: true)
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
            // Keep last snapshot (including persisted lock/warning). Never fail-open to Home.
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

    private func applyInternal(_ next: AppMaintenanceStatus, fromNetwork: Bool) {
        let prev = status
        status = next
        isReady = true
        if next.sawRestricted {
            sawRestrictedThisSession = true
        }
        if fromNetwork {
            maybeQueueResume(prev: prev, next: next)
        }
        persistSnapshot(next)
    }

    private func persistSnapshot(_ next: AppMaintenanceStatus) {
        let phase: String
        if next.isLocked {
            phase = "maintenance"
        } else if next.isWarning {
            phase = "warning"
        } else {
            phase = "open"
        }
        UserDefaults.standard.set(next.isLocked, forKey: Self.persistedOnKey)
        UserDefaults.standard.set(phase, forKey: Self.persistedPhaseKey)
        UserDefaults.standard.set(next.startsAtIso, forKey: Self.persistedStartsAtKey)
        UserDefaults.standard.set(next.countdownSeconds, forKey: Self.persistedCountdownKey)
        UserDefaults.standard.set(next.title, forKey: Self.persistedTitleKey)
        UserDefaults.standard.set(next.message, forKey: Self.persistedMessageKey)
    }

    private func maybeQueueResume(prev: AppMaintenanceStatus, next: AppMaintenanceStatus) {
        guard sawRestrictedThisSession else { return }
        guard let moment = next.inferredResumeMoment(previous: prev) else { return }
        let token = next.resumeDedupeToken(previous: prev)
        guard !token.isEmpty, !Self.hasSeenResume(token) else { return }
        pendingResume = MaintenanceResumePresentation(
            moment: moment,
            releaseNotesTitle: next.resumeTitle(previous: prev),
            releaseNotes: next.resumeBody(previous: prev),
            updatedAtToken: token
        )
    }

    private func startConnectivityRefresh() {
        guard pathMonitor == nil else { return }
        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            let ok = path.status == .satisfied
            Task { @MainActor in
                guard let self else { return }
                let prev = self.lastPathSatisfied
                self.lastPathSatisfied = ok
                if ok, prev == false {
                    await self.refreshNow()
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    private static func hasSeenResume(_ token: String) -> Bool {
        UserDefaults.standard.string(forKey: seenResumeKey) == token
    }

    private static func markResumeSeen(_ token: String) {
        UserDefaults.standard.set(token, forKey: seenResumeKey)
    }

    private static func loadPersisted() -> AppMaintenanceStatus {
        let phase = UserDefaults.standard.string(forKey: persistedPhaseKey) ?? ""
        let startsAt = UserDefaults.standard.string(forKey: persistedStartsAtKey)
        let countdown = UserDefaults.standard.integer(forKey: persistedCountdownKey)
        let title = UserDefaults.standard.string(forKey: persistedTitleKey)
        let message = UserDefaults.standard.string(forKey: persistedMessageKey)
        let locked = UserDefaults.standard.bool(forKey: persistedOnKey) ||
            phase.caseInsensitiveCompare("maintenance") == .orderedSame
        if locked {
            return AppMaintenanceStatus(
                maintenance: true,
                phase: "maintenance",
                mode: "none",
                startsAtIso: startsAt,
                countdownSeconds: countdown,
                title: title,
                message: message,
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
                startsAtIso: startsAt,
                countdownSeconds: countdown,
                title: title,
                message: message,
                updatedAtIso: nil,
                resumeMoment: nil,
                releaseNotesTitle: nil,
                releaseNotes: nil
            )
        }
        return .open
    }
}
