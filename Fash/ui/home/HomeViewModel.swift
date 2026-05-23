import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var isLoading = false
    var items: [ListingFeedItem] = []
    var errorMessage: String?

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
