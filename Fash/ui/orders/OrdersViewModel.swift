import Foundation
import Observation

/// Observable port of Android `OrdersViewModel` (ui.orders).
@Observable
@MainActor
final class OrdersViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android OrdersViewModel.kt
    }
}
