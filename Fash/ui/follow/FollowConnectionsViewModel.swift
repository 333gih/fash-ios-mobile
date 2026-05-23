import Foundation
import Observation

/// Observable port of Android `FollowConnectionsViewModel` (ui.follow).
@Observable
@MainActor
final class FollowConnectionsViewModel {
    var isLoading = false
    var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        // Port logic from Android FollowConnectionsViewModel.kt
    }
}
