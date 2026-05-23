import Foundation
import Observation

/// Observable port of Android `LoginHeroSlidesViewModel` (ui.login).
@Observable
@MainActor
final class LoginHeroSlidesViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android LoginHeroSlidesViewModel.kt
    }
}
