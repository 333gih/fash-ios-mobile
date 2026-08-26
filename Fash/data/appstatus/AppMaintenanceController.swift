import Foundation
import Observation

@Observable
@MainActor
final class AppMaintenanceController {
    private static let persistedOnKey = "fash.app.maintenance.last"
    private static let persistedPhaseKey = "fash.app.maintenance.phase"
    private static let persistedStartsAtKey = "fash.app.maintenance.starts_at"
    private static let persistedCountdownKey = "fash.app.maintenance.countdown"
    private static let seenResumeKey = "fash.app.maintenance.seen_resume"

    private(set) var status: AppMaintenanceStatus
    /// Persisted snapshot is enough to paint the first frame — do not block Home on GET /app/status.
    private(set) var isReady: Bool = true
    private(set) var pendingResume: MaintenanceResumePresentation?
    var isMaintenance: Bool { status.isEffectivelyLocked() }
    var isWarning: Bool { status.isWarning && !status.isEffectivelyLocked() }

    private var sawRestrictedThisSession = false
    private var confirmedFromNetwork = false
    private let repository: AppStatusRepository

    init(repository: AppStatusRepository) {
        self.repository = repository
        self.status = Self.loadPersisted()
        if status.sawRestricted {
            sawRestrictedThisSession = true
        }
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
            // Keep a persisted lock (user can retry). Only fail-open when we were not locked.
            if !confirmedFromNetwork && !status.isLocked {
                applyInternal(.open, fromNetwork: false)
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

    private func applyInternal(_ next: AppMaintenanceStatus, fromNetwork: Bool) {
        let prev = status
        status = next
        isReady = true
        if fromNetwork {
            confirmedFromNetwork = true
        }
        if next.sawRestricted {
            sawRestrictedThisSession = true
        }
        if fromNetwork {
            maybeQueueResume(prev: prev, next: next)
        }
        persistSnapshot(next)
    }

    private func persistSnapshot(_ next: AppMaintenanceStatus) {
        // Warning is a 60s in-session state — persisting it makes the next cold start look locked
        // after the countdown has elapsed.
        let persistLocked = next.isLocked
        UserDefaults.standard.set(persistLocked, forKey: Self.persistedOnKey)
        UserDefaults.standard.set(persistLocked ? "maintenance" : "open", forKey: Self.persistedPhaseKey)
        UserDefaults.standard.set(next.startsAtIso, forKey: Self.persistedStartsAtKey)
        UserDefaults.standard.set(next.countdownSeconds, forKey: Self.persistedCountdownKey)
    }

    private func maybeQueueResume(prev: AppMaintenanceStatus, next: AppMaintenanceStatus) {
        guard sawRestrictedThisSession else { return }
        guard let moment = next.inferredResumeMoment(previous: prev) else { return }
        let token = next.resumeDedupeToken(previous: prev)
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
        let startsAt = UserDefaults.standard.string(forKey: persistedStartsAtKey)
        let countdown = UserDefaults.standard.integer(forKey: persistedCountdownKey)
        let locked = UserDefaults.standard.bool(forKey: persistedOnKey) ||
            phase.caseInsensitiveCompare("maintenance") == .orderedSame
        if locked {
            return AppMaintenanceStatus(
                maintenance: true,
                phase: "maintenance",
                mode: "none",
                startsAtIso: startsAt,
                countdownSeconds: countdown,
                title: nil,
                message: nil,
                updatedAtIso: nil,
                resumeMoment: nil,
                releaseNotesTitle: nil,
                releaseNotes: nil
            )
        }
        // Stale warning snapshots from older builds must not lock the next launch.
        return .open
    }
}
