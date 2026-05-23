import Foundation
import Observation

/// Observable port of Android `NotificationsViewModel` (ui.notifications).
@Observable
@MainActor
final class NotificationsViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android NotificationsViewModel.kt
    }
}
