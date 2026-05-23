import Foundation
import Observation

/// Observable port of Android `UiDialogViewModel` (ui.common).
@Observable
@MainActor
final class UiDialogViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android UiDialogViewModel.kt
    }
}
