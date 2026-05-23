import Foundation
import Observation

/// Observable port of Android `PendingPaymentViewModel` (ui.orders).
@Observable
@MainActor
final class PendingPaymentViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android PendingPaymentViewModel.kt
    }
}
