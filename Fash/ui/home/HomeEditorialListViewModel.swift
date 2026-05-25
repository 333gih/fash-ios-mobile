import Foundation
import Observation

/// Observable port of Android `HomeEditorialListViewModel` (ui.home).
@Observable
@MainActor
final class HomeEditorialListViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android HomeEditorialListViewModel.kt
    }
}
