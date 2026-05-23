import Foundation
import Observation

/// Observable port of Android `OrderDetailViewModel` (ui.orders).
@Observable
@MainActor
final class OrderDetailViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android OrderDetailViewModel.kt
    }
}
