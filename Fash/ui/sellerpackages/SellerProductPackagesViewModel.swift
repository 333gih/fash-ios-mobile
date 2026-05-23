import Foundation
import Observation

/// Observable port of Android `SellerProductPackagesViewModel` (ui.sellerpackages).
@Observable
@MainActor
final class SellerProductPackagesViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android SellerProductPackagesViewModel.kt
    }
}
