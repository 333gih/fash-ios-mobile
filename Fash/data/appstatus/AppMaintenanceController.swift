import Foundation
import Observation

@Observable
@MainActor
final class AppMaintenanceController {
    private static let persistedOnKey = "fash.app.maintenance.last"
    private static let persistedPhaseKey = "fash.app.maintenance.phase"

    private(set) var status: AppMaintenanceStatus
    private(set) var isReady: Bool = false
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
        status = next
        isReady = true
        if next.sawRestricted {
            sawRestrictedThisSession = true
        }
        UserDefaults.standard.set(next.isLocked, forKey: Self.persistedOnKey)
        UserDefaults.standard.set(next.phase, forKey: Self.persistedPhaseKey)
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
                message: nil
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
                message: nil
            )
        }
        return .open
    }
}
