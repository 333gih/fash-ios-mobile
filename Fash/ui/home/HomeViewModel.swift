import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var isLoading = false
    var isRefreshing = false
    var items: [ListingFeedItem] = []
    var errorMessage: String?
    var selectedFeedTabKey = "hunt_today"
    var featuredSellers: [FeaturedSellerItem] = []
    var promoSlides: [AppAdvertisingSlideItem] = []

    private var sections = HomeRecommendationSections()

    func onGuestBrowseEntered() {
        selectedFeedTabKey = "hunt_today"
        items = []
        errorMessage = nil
        featuredSellers = []
    }

    func clearCachesForSignedOutUser() {
        onGuestBrowseEntered()
    }

    var selectedFeedTab: HomeFeedTab {
        HomeFeedTab(rawValue: selectedFeedTabKey) ?? .huntToday
    }

    func selectFeedTab(_ tab: HomeFeedTab) {
        selectedFeedTabKey = tab.rawValue
        items = itemsForTab(sections, tabKey: tab.rawValue)
    }

    func normalizeSelectedFeedTab(isGuestMode: Bool) {
        let allowed = HomeFeedTab.tabsFor(isGuestBrowse: isGuestMode)
        if !allowed.contains(selectedFeedTab) {
            selectFeedTab(.huntToday)
        }
    }

    func refresh(deps: AppDependencies, isGuestMode: Bool = false) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        normalizeSelectedFeedTab(isGuestMode: isGuestMode)

        async let sectionsResult = deps.recommendationRepository.homeSections(publicBrowse: isGuestMode)
        async let sellersResult = deps.searchRepository.getFeaturedSellers(limit: 12, publicBrowse: isGuestMode)
        async let slidesResult = deps.advertisingRepository.getSlides(publicBrowse: isGuestMode)

        switch await sectionsResult {
        case .success(let loaded):
            sections = loaded
            items = itemsForTab(loaded, tabKey: selectedFeedTabKey)
            if items.isEmpty, !isGuestMode, selectedFeedTabKey == "following" {
                await loadFollowFeedFallback(deps: deps)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            if !isGuestMode, selectedFeedTabKey == "following" {
                await loadFollowFeedFallback(deps: deps)
            }
        }

        if case .success(let sellers) = await sellersResult {
            featuredSellers = sellers
        }
        if case .success(let slides) = await slidesResult {
            promoSlides = slides.items
        }
    }

    func pullToRefresh(deps: AppDependencies, isGuestMode: Bool = false) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    private func itemsForTab(_ sections: HomeRecommendationSections, tabKey: String) -> [ListingFeedItem] {
        switch tabKey {
        case "for_you":
            return sections.forYou
        case "style_picks":
            return sections.stylePicks
        case "similar_saved":
            return sections.similarToSaved
        case "following":
            return sections.continueBrowsing
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
