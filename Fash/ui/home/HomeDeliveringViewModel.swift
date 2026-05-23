import Foundation
import Observation

/// Observable port of Android `HomeDeliveringViewModel` (ui.home).
@Observable
@MainActor
final class HomeDeliveringViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android HomeDeliveringViewModel.kt
    }
}
