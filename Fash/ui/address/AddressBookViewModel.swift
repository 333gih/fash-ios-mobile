import Foundation
import Observation

/// Observable port of Android `AddressBookViewModel` (ui.address).
@Observable
@MainActor
final class AddressBookViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android AddressBookViewModel.kt
    }
}
