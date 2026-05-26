import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var isLoading = false
    var items: [ListingFeedItem] = []
    var errorMessage: String?
    /// Mirrors Android default home feed tab after guest browse / sign-out.
    var selectedFeedTabKey = "hunt_today"

    func onGuestBrowseEntered() {
        selectedFeedTabKey = "hunt_today"
        items = []
        errorMessage = nil
    }

    func clearCachesForSignedOutUser() {
        onGuestBrowseEntered()
    }

    func refresh(deps: AppDependencies) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let result = await deps.listingRepository.getHomeFeed()
        switch result {
        case .success(let feed):
            items = feed
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
