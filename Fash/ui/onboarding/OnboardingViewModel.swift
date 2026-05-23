import Foundation
import Observation

/// Observable port of Android `OnboardingViewModel` (ui.onboarding).
@Observable
@MainActor
final class OnboardingViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android OnboardingViewModel.kt
    }
}
