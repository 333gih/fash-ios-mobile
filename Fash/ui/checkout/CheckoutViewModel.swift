import Foundation
import Observation

/// Observable port of Android `CheckoutViewModel` (ui.checkout).
@Observable
@MainActor
final class CheckoutViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android CheckoutViewModel.kt
    }
}
