import Foundation
import Observation

/// Observable port of Android `ChangePasswordViewModel` (ui.settings).
@Observable
@MainActor
final class ChangePasswordViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android ChangePasswordViewModel.kt
    }
}
