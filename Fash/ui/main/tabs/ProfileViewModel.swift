import Foundation
import Observation

private let profileStaleThresholdSeconds: TimeInterval = 60

struct ProfileTabOpenRequest: Equatable {
    let tab: ProfileListingTab
    let scrollToGrid: Bool
}

@Observable
@MainActor
final class ProfileViewModel {
    var profile: ProfileInfo?
    var aestheticCatalog: [CommonAestheticTagDto] = []
    var displayName = ""
    var username = ""
    var avatarUrl = ""
    var coverImageUrl = ""
    var bio = ""
    var followerCount = 0
    var followingCount = 0
    var productCount = 0
    var soldCount = 0
    var isLoading = false
    var isRefreshing = false
    var loadError = false
    /// False until profile + summary + first tab listings finish — blocks scroll until ready.
    var hasCompletedInitialLoad = false
    var isSupplementalListingsLoading = false
    var tabCounts = ProfileListingsSummary()
    var profileUxPersonalization = ProfileUxPersonalization()
    var orderedProfileTabIndices: [Int] = ProfileListingTab.allCases.map(\.rawValue)
    var profileTabOpenGeneration = 0

    var sellingListings: [ListingFeedItem] = []
    var inReviewListings: [ListingFeedItem] = []
    var rejectedListings: [ListingFeedItem] = []
    var soldListings: [ListingFeedItem] = []
    var wishlistListings: [ListingFeedItem] = []

    private var lastSuccessfulRefreshAt: Date?
    private var profileUxDefaultApplied = false
    private var pendingDefaultProfileTab: Int?
    private var profileTabOpenRequest: ProfileTabOpenRequest?
    private var loadedListingTabs = Set<Int>()

    func listings(for tab: ProfileListingTab) -> [ListingFeedItem] {
        switch tab {
        case .active: return sellingListings
        case .inReview: return inReviewListings
        case .rejected: return rejectedListings
        case .sold: return soldListings
        case .wishlist: return wishlistListings
        }
    }

    /// Badge count from server summary (not `listings.count` — capped at 50 per fetch).
    func displayCount(for tab: ProfileListingTab) -> Int {
        switch tab {
        case .active: return tabCounts.active
        case .inReview: return tabCounts.inReview
        case .rejected: return tabCounts.rejected
        case .sold: return tabCounts.sold
        case .wishlist: return tabCounts.wishlist
        }
    }

    func refreshIfStale(deps: AppDependencies) async {
        if let last = lastSuccessfulRefreshAt,
           Date().timeIntervalSince(last) < profileStaleThresholdSeconds {
            return
        }
        await refresh(deps: deps, force: false)
    }

    func refresh(deps: AppDependencies, force: Bool = true) async {
        if !force,
           let last = lastSuccessfulRefreshAt,
           Date().timeIntervalSince(last) < profileStaleThresholdSeconds {
            return
        }
        let showBlocking = profile == nil
        if showBlocking {
            hasCompletedInitialLoad = false
            isLoading = true
        } else {
            isRefreshing = true
        }
        loadError = false
        defer { isLoading = false; isRefreshing = false }

        async let profileResult = deps.userRepository.getMeProfile()
        async let tagsResult = deps.commonCatalogRepository.getAestheticTags(all: true)
        async let summaryResult = deps.listingRepository.getMyListingsSummary()

        switch await profileResult {
        case .success(let p):
            applyProfile(p)
            lastSuccessfulRefreshAt = Date()
            loadError = false
            if case .success(let summary) = await summaryResult {
                tabCounts = summary
            } else if !hasCompletedInitialLoad {
                tabCounts = ProfileListingsSummary()
            }
            applyProfileListingMetricsFromSummary()
            if case .success(let tags) = await tagsResult {
                aestheticCatalog = tags
            }
            async let uxTask: Void = loadProfileUxPersonalization(deps: deps)
            if hasCompletedInitialLoad {
                await reloadAllListingTabs(deps: deps)
            } else {
                let initialTab = resolveInitialTabIndex()
                await loadListingsForTab(ProfileListingTab(rawValue: initialTab) ?? .active, deps: deps, force: true)
                hasCompletedInitialLoad = true
                prefetchRemainingTabs(except: initialTab, deps: deps)
            }
            await uxTask
        case .failure:
            loadError = true
            hasCompletedInitialLoad = true
        }
    }

    func onProfileTabSelected(_ tabIndex: Int, deps: AppDependencies) {
        deps.uxTabTracker.onTabOpened(scope: "profile", tabKey: UxPersonalizationMapping.profileTabKey(from: tabIndex))
        let tab = ProfileListingTab(rawValue: tabIndex) ?? .active
        Task { await loadListingsForTab(tab, deps: deps, force: false) }
    }

    func requestWishlistTabFromHome(deps: AppDependencies) {
        requestOpenProfileTab(.wishlist, scrollToGrid: true)
        Task {
            if profile == nil {
                await refresh(deps: deps, force: true)
            } else {
                await refreshIfStale(deps: deps)
                await loadListingsForTab(.wishlist, deps: deps, force: true)
            }
        }
    }

    func requestInReviewTabFromHome(deps: AppDependencies) {
        requestOpenProfileTab(.inReview, scrollToGrid: true)
        Task {
            if profile == nil {
                await refresh(deps: deps, force: true)
            } else {
                await refreshIfStale(deps: deps)
                await loadListingsForTab(.inReview, deps: deps, force: true)
            }
        }
    }

    func consumeProfileTabOpenRequest() -> ProfileTabOpenRequest? {
        guard profileTabOpenGeneration != 0 else { return nil }
        let req = profileTabOpenRequest
        profileTabOpenRequest = nil
        profileTabOpenGeneration = 0
        return req
    }

    func consumePendingDefaultProfileTab() -> Int? {
        if profileUxDefaultApplied { return nil }
        if profileTabOpenGeneration != 0 { return nil }
        let tab = pendingDefaultProfileTab
            ?? UxPersonalizationMapping.profileTabIndex(from: profileUxPersonalization.defaultTabKey)
        pendingDefaultProfileTab = nil
        guard let tab else { return nil }
        profileUxDefaultApplied = true
        return tab
    }

    func clearCachedProfile(deps: AppDependencies) {
        profileUxDefaultApplied = false
        profileUxPersonalization = ProfileUxPersonalization()
        orderedProfileTabIndices = ProfileListingTab.allCases.map(\.rawValue)
        profileTabOpenRequest = nil
        profileTabOpenGeneration = 0
        pendingDefaultProfileTab = nil
        deps.uxTabTracker.closeActiveTab()
        deps.uxTabTracker.flush()
        profile = nil
        sellingListings = []
        inReviewListings = []
        rejectedListings = []
        soldListings = []
        wishlistListings = []
        tabCounts = ProfileListingsSummary()
        loadedListingTabs = []
        loadError = false
        lastSuccessfulRefreshAt = nil
        hasCompletedInitialLoad = false
        isSupplementalListingsLoading = false
    }

    private func applyProfile(_ p: ProfileInfo) {
        profile = p
        displayName = p.displayName.isEmpty ? p.username : p.displayName
        username = p.username
        avatarUrl = p.avatarUrl
        coverImageUrl = p.coverImageUrl
        bio = p.bio
        followerCount = p.followerCount
        followingCount = p.followingCount
        productCount = p.productCount
        soldCount = p.soldCount
    }

    private func applyProfileListingMetricsFromSummary() {
        if tabCounts.sold > 0 { soldCount = tabCounts.sold }
        let listed = tabCounts.active + tabCounts.inReview + tabCounts.rejected
        if listed > 0 { productCount = listed }
    }

    private func resolveInitialTabIndex() -> Int {
        if profileTabOpenGeneration != 0, let req = profileTabOpenRequest {
            return req.tab.rawValue
        }
        if let pending = pendingDefaultProfileTab {
            return pending
        }
        if let idx = UxPersonalizationMapping.profileTabIndex(from: profileUxPersonalization.defaultTabKey) {
            return idx
        }
        return ProfileListingTab.active.rawValue
    }

    private func prefetchRemainingTabs(except initialTab: Int, deps: AppDependencies) {
        Task {
            for tab in ProfileListingTab.allCases where tab.rawValue != initialTab {
                await loadListingsForTab(tab, deps: deps, force: false)
            }
        }
    }

    private func reloadAllListingTabs(deps: AppDependencies) async {
        for tab in ProfileListingTab.allCases {
            await loadListingsForTab(tab, deps: deps, force: true)
        }
    }

    private func loadListingsForTab(_ tab: ProfileListingTab, deps: AppDependencies, force: Bool = false) async {
        if !force, loadedListingTabs.contains(tab.rawValue) { return }
        let showSpinner = hasCompletedInitialLoad && listings(for: tab).isEmpty && !isRefreshing
        if showSpinner { isSupplementalListingsLoading = true }
        defer {
            if showSpinner { isSupplementalListingsLoading = false }
            loadedListingTabs.insert(tab.rawValue)
        }

        switch tab {
        case .wishlist:
            guard case .success(let wish) = await deps.listingRepository.getWishlistListings(limit: 50, offset: 0) else {
                return
            }
            wishlistListings = wish
        case .active:
            guard case .success(let list) = await deps.listingRepository.getMyListings(status: "active", limit: 50, offset: 0) else {
                return
            }
            sellingListings = list
        case .inReview:
            guard case .success(let list) = await deps.listingRepository.getMyListings(status: "in_review", limit: 50, offset: 0) else {
                return
            }
            inReviewListings = list
        case .rejected:
            guard case .success(let list) = await deps.listingRepository.getMyListings(status: "rejected", limit: 50, offset: 0) else {
                return
            }
            rejectedListings = list
        case .sold:
            guard case .success(let list) = await deps.listingRepository.getMyListings(status: "sold", limit: 50, offset: 0) else {
                return
            }
            soldListings = list
            if soldCount == 0 { soldCount = list.count }
        }
    }

    private func loadProfileUxPersonalization(deps: AppDependencies) async {
        let uid = deps.authSessionStore.read()?.userId
        if let local = UxPersonalizationLocalStore.readProfileDefaultTab(userId: uid),
           let idx = UxPersonalizationMapping.profileTabIndex(from: local),
           !profileUxDefaultApplied {
            profileUxPersonalization.defaultTabKey = local
            pendingDefaultProfileTab = idx
        }
        let result = await deps.recommendationRepository.uxPersonalization(
            clientHour: UxPersonalizationLocalStore.currentClientHour()
        )
        guard case .success(let bundle) = result else { return }
        profileUxPersonalization = bundle.profile
        orderedProfileTabIndices = UxPersonalizationMapping.orderedProfileTabIndices(
            tabOrderKeys: bundle.profile.tabOrderKeys
        )
        UxPersonalizationLocalStore.writeProfileDefaultTab(userId: uid, tabKey: bundle.profile.defaultTabKey)
        if let idx = UxPersonalizationMapping.profileTabIndex(from: bundle.profile.defaultTabKey),
           !profileUxDefaultApplied {
            pendingDefaultProfileTab = idx
        }
    }

    private func requestOpenProfileTab(_ tab: ProfileListingTab, scrollToGrid: Bool) {
        profileTabOpenRequest = ProfileTabOpenRequest(tab: tab, scrollToGrid: scrollToGrid)
        profileTabOpenGeneration += 1
    }

    func toggleLike(_ item: ListingFeedItem, deps: AppDependencies) async {
        let snapshot = item
        guard deps.listingEngagement.beginLikeToggle(listingId: item.id) else { return }
        patchListing(item.id) { _ in snapshot.toggledLike }
        defer { deps.listingEngagement.endLikeToggle(listingId: item.id) }
        switch await deps.listingRepository.toggleLike(listingId: item.id) {
        case .success(let liked):
            patchListing(item.id) { _ in snapshot.applyingLikeToggle(liked) }
            deps.showSnackbar(FeedEngagementFeedback.likeMessage(liked: liked))
        case .failure(let error):
            patchListing(item.id) { _ in snapshot }
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        }
    }

    func toggleSave(_ item: ListingFeedItem, deps: AppDependencies) async {
        let snapshot = item
        guard deps.listingEngagement.beginSaveToggle(listingId: item.id) else { return }
        patchListing(item.id) { _ in snapshot.toggledSave }
        defer { deps.listingEngagement.endSaveToggle(listingId: item.id) }
        switch await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: snapshot.isSaved) {
        case .success(let saved):
            patchListing(item.id) { _ in snapshot.applyingSaveToggle(saved) }
            if !saved && snapshot.isSaved {
                wishlistListings.removeAll { $0.id == item.id }
                tabCounts.wishlist = max(0, tabCounts.wishlist - 1)
            } else if saved {
                let patched = snapshot.applyingSaveToggle(true)
                if !wishlistListings.contains(where: { $0.id == item.id }) {
                    wishlistListings.insert(patched, at: 0)
                }
                tabCounts.wishlist += 1
            }
            deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
        case .failure(let error):
            patchListing(item.id) { _ in snapshot }
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        }
    }

    private func patchListing(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        sellingListings = sellingListings.map { $0.id == id ? transform($0) : $0 }
        inReviewListings = inReviewListings.map { $0.id == id ? transform($0) : $0 }
        rejectedListings = rejectedListings.map { $0.id == id ? transform($0) : $0 }
        soldListings = soldListings.map { $0.id == id ? transform($0) : $0 }
        wishlistListings = wishlistListings.map { $0.id == id ? transform($0) : $0 }
    }
}
