import Foundation
import Observation

/// Observable port of Android `EditProfileViewModel` (ui.profile).
@Observable
@MainActor
final class EditProfileViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android EditProfileViewModel.kt
    }
}
