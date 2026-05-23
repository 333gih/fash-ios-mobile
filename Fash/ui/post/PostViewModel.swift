import Foundation
import Observation

/// Observable port of Android `PostViewModel` (ui.post).
@Observable
@MainActor
final class PostViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android PostViewModel.kt
    }
}
