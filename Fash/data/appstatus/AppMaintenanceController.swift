import Foundation
import Observation

@Observable
@MainActor
final class AppMaintenanceController {
    private(set) var status: AppMaintenanceStatus = .open
    var isMaintenance: Bool { status.maintenance }

    private let repository: AppStatusRepository

    init(repository: AppStatusRepository) {
        self.repository = repository
    }

    func refreshNow() async {
        do {
            status = try await repository.fetch()
        } catch {
            // Keep last successful status (fail-open unless already in maintenance).
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
