import Foundation
import Observation

/// Observable port of Android `UserExperienceSurveyViewModel` (ui.home).
@Observable
@MainActor
final class UserExperienceSurveyViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android UserExperienceSurveyViewModel.kt
    }
}
