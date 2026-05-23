import Foundation
import Observation

/// Observable port of Android `HomeEditorialDetailViewModel` (ui.home).
@Observable
@MainActor
final class HomeEditorialDetailViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android HomeEditorialDetailViewModel.kt
    }
}
