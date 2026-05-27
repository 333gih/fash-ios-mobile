import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var isLoading = false
    var isRefreshing = false
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

    func refresh(deps: AppDependencies, isGuestMode: Bool = false) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let sectionsResult = await deps.recommendationRepository.homeSections(publicBrowse: isGuestMode)
        switch sectionsResult {
        case .success(let sections):
            items = itemsForTab(sections)
            if items.isEmpty, !isGuestMode {
                await loadFollowFeedFallback(deps: deps)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            if !isGuestMode {
                await loadFollowFeedFallback(deps: deps)
            }
        }
    }

    func pullToRefresh(deps: AppDependencies, isGuestMode: Bool = false) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    private func itemsForTab(_ sections: HomeRecommendationSections) -> [ListingFeedItem] {
        switch selectedFeedTabKey {
        case "for_you":
            return sections.forYou
        case "style_picks":
            return sections.stylePicks
        case "continue_browsing":
            return sections.continueBrowsing
        case "similar_to_saved":
            return sections.similarToSaved
        default:
            if !sections.huntToday.isEmpty { return sections.huntToday }
            if !sections.forYou.isEmpty { return sections.forYou }
            return sections.huntToday
        }
    }

    private func loadFollowFeedFallback(deps: AppDependencies) async {
        let result = await deps.listingRepository.getHomeFeed(limit: 40)
        if case .success(let feed) = result, !feed.isEmpty {
            items = feed
            errorMessage = nil
        }
    }
}
