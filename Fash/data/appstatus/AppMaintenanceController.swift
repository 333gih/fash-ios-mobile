import Foundation
import Observation

@Observable
@MainActor
final class AppMaintenanceController {
    private static let persistedKey = "fash.app.maintenance.last"

    private(set) var status: AppMaintenanceStatus
    private(set) var isReady: Bool = false
    var isMaintenance: Bool { status.maintenance }

    private let repository: AppStatusRepository

    init(repository: AppStatusRepository) {
        self.repository = repository
        if UserDefaults.standard.bool(forKey: Self.persistedKey) {
            self.status = AppMaintenanceStatus(maintenance: true, title: nil, message: nil)
        } else {
            self.status = .open
        }
    }

    func apply(_ next: AppMaintenanceStatus) {
        status = next
        isReady = true
        UserDefaults.standard.set(next.maintenance, forKey: Self.persistedKey)
    }

    func applyFromPushData(_ data: [String: String]) -> Bool {
        let type = (data["type"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard type == "app.maintenance" || type == "app.status.changed" else { return false }
        let raw = data["maintenance"] ?? data["enabled"] ?? ""
        let on = ["true", "1", "yes"].contains(raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        apply(AppMaintenanceStatus(
            maintenance: on,
            title: data["title"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            message: data["message"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        ))
        return true
    }

    func refreshNow() async {
        do {
            apply(try await repository.fetch())
        } catch {
            isReady = true
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
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
