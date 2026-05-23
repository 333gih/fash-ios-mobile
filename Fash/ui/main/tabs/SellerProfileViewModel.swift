import Foundation
import Observation

/// Observable port of Android `SellerProfileViewModel` (ui.main.tabs).
@Observable
@MainActor
final class SellerProfileViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android SellerProfileViewModel.kt
    }
}
