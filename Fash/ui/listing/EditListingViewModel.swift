import Foundation
import Observation

/// Observable port of Android `EditListingViewModel` (ui.listing).
@Observable
@MainActor
final class EditListingViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android EditListingViewModel.kt
    }
}
