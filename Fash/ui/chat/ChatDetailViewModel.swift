import Foundation
import Observation

/// Observable port of Android `ChatDetailViewModel` (ui.chat).
@Observable
@MainActor
final class ChatDetailViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android ChatDetailViewModel.kt
    }
}
