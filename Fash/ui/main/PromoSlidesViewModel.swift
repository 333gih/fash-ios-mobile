import Foundation
import Observation

/// Observable port of Android `PromoSlidesViewModel` (ui.main).
@Observable
@MainActor
final class PromoSlidesViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android PromoSlidesViewModel.kt
    }
}
