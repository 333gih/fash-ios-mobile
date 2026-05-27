import Foundation
import Observation

@Observable
@MainActor
final class ExploreViewModel {
    var query = ""
    var items: [ListingFeedItem] = []
    var isLoading = false
    var isRefreshing = false
    var loadError = false

    func refresh(deps: AppDependencies, isGuestMode: Bool) async {
        isLoading = true
        loadError = false
        defer { isLoading = false }
        let q = query.trimmingCharacters(in: .whitespaces)
        let result: Result<[ListingFeedItem], Error>
        if q.isEmpty {
            result = await deps.recommendationRepository.exploreListings(
                publicBrowse: isGuestMode,
                limit: 20,
                offset: 0
            )
        } else if isGuestMode {
            result = await deps.searchRepository.browseListings(q: q, limit: 40, offset: 0)
        } else {
            result = await deps.searchRepository.searchListings(q: q, limit: 40, offset: 0)
        }
        switch result {
        case .success(let feed):
            items = feed
            loadError = false
        case .failure:
            items = []
            loadError = true
        }
    }

    func pullToRefresh(deps: AppDependencies, isGuestMode: Bool) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }
}
