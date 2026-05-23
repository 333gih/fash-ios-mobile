import Foundation
import Observation

/// Observable port of Android `FeaturedSellersViewModel` (ui.explore).
@Observable
@MainActor
final class FeaturedSellersViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android FeaturedSellersViewModel.kt
    }
}
