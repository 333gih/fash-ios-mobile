import Foundation
import Observation
import SwiftUI

private let profileStaleThresholdSeconds: TimeInterval = 60

/// Paginated per tab — same page size and window policy as [SellerProfileViewModel].
private enum ProfileListingConstants {
    static let listingPageSize = 20
    static let imagePrefetchCap = 8
    static let slidingWindowPolicy = FeedSlidingWindowPolicy.sellerStorefront
}

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
    /// Profile shell + summary ready — listing grid may still load first page.
    var hasCompletedInitialLoad = false
    var listingTabsStalled: Set<Int> = []
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
    private(set) var lastSelectedProfileTab = ProfileListingTab.active.rawValue
    private var tabPagination: [Int: ProfileTabPagination] = [:]
    private var loadMoreTasks: [Int: Task<Void, Never>] = [:]
    private let listingStallWatch = FeedLoadStallWatch()
    var focusListingScrollToken = 0
    private(set) var focusListingId: String?
    /// Bottom-nav re-tap — scroll profile list to top (Android `scrollProfileToTop`).
    private(set) var profileScrollToTopToken = 0
    var listingScrollTrimToken = 0
    private(set) var listingScrollTrimSignedDeltaY: CGFloat = 0

    private var listingWindows: [Int: ProfileListingWindowState] = [:]
    private var backfillTasks: [Int: Task<Void, Never>] = [:]
    private var trimTasks: [Int: Task<Void, Never>] = [:]

    private struct ProfileListingWindowState {
        var window = FeedSlidingWindow()
        var knownIds = Set<String>()
        var isBackfilling = false
    }

    /// Scroll boundary from [HomeFeedScrollCoordinator] — gates trim/backfill while finger is on screen.
    @ObservationIgnored
    var scrollBoundary: HomeFeedScrollBoundary?

    func requestScrollProfileToTop() {
        profileScrollToTopToken &+= 1
    }

    func listings(for tab: ProfileListingTab) -> [ListingFeedItem] {
        switch tab {
        case .active: return sellingListings
        case .inReview: return inReviewListings
        case .rejected: return rejectedListings
        case .sold: return soldListings
        case .wishlist: return wishlistListings
        }
    }

    /// Badge count from server summary (not `listings.count` — paginated fetches).
    func displayCount(for tab: ProfileListingTab) -> Int {
        switch tab {
        case .active: return tabCounts.active
        case .inReview: return tabCounts.inReview
        case .rejected: return tabCounts.rejected
        case .sold: return tabCounts.sold
        case .wishlist: return tabCounts.wishlist
        }
    }

    func hasMoreListings(for tab: ProfileListingTab) -> Bool {
        pagination(for: tab).hasMore
    }

    func isLoadingMoreListings(for tab: ProfileListingTab) -> Bool {
        pagination(for: tab).isLoadingMore
    }

    func isReloadingListings(for tab: ProfileListingTab) -> Bool {
        pagination(for: tab).isReloading
    }

    /// First page in flight while grid is still empty (Explore-style skeleton).
    func isFirstPageLoading(for tab: ProfileListingTab) -> Bool {
        let p = pagination(for: tab)
        return listings(for: tab).isEmpty && (p.isLoadingFirstPage || p.isReloading)
    }

    func requestLoadMore(for tab: ProfileListingTab, deps: AppDependencies) {
        guard canLoadMore(for: tab) else { return }
        guard loadMoreTasks[tab.rawValue] == nil else { return }
        loadMoreTasks[tab.rawValue] = Task { @MainActor in
            defer { loadMoreTasks[tab.rawValue] = nil }
            await loadMoreListings(for: tab, deps: deps)
        }
    }

    /// TikTok-style window — trim/backfill only after scroll idle (never while dragging).
    func notifyListingCellVisible(
        tab: ProfileListingTab,
        visibleIndex: Int,
        columnWidth: CGFloat,
        deps: AppDependencies
    ) {
        guard columnWidth > 1 else { return }
        scheduleDeferredWindowMaintenance(
            tab: tab,
            visibleIndex: visibleIndex,
            columnWidth: columnWidth,
            deps: deps
        )
    }

    func refreshIfStale(deps: AppDependencies) async {
        if let last = lastSuccessfulRefreshAt,
           Date().timeIntervalSince(last) < profileStaleThresholdSeconds {
            await ensureListingsLoaded(for: currentProfileTab(), deps: deps)
            return
        }
        await refresh(deps: deps, force: false, activeTab: currentProfileTab())
    }

    /// Loads the first page for a tab when it has never succeeded, or retries when badge count implies listings exist.
    func prepareEditReturn(tab: ProfileListingTab, listingId: String) {
        lastSelectedProfileTab = tab.rawValue
        focusListingId = listingId
    }

    /// After closing edit — refresh active tab only and scroll back to the edited listing.
    func completeEditReturn(tab: ProfileListingTab, listingId: String, deps: AppDependencies) async {
        lastSelectedProfileTab = tab.rawValue
        focusListingId = listingId
        loadedListingTabs.remove(tab.rawValue)
        await fetchListingsFirstPage(tab, deps: deps, force: true)
        focusListingScrollToken += 1
    }

    func ensureListingsLoaded(for tab: ProfileListingTab, deps: AppDependencies) async {
        guard profile != nil else { return }
        guard !isFirstPageLoading(for: tab), !isReloadingListings(for: tab) else { return }
        guard listings(for: tab).isEmpty else { return }
        if loadedListingTabs.contains(tab.rawValue) {
            guard displayCount(for: tab) > 0 else { return }
            loadedListingTabs.remove(tab.rawValue)
        }
        await loadListingsForTab(tab, deps: deps, force: false)
    }

    func isListingTabStalled(_ tab: ProfileListingTab) -> Bool {
        listingTabsStalled.contains(tab.rawValue)
    }

    func shouldShowListingGridSkeleton(for tab: ProfileListingTab) -> Bool {
        if isListingTabStalled(tab) { return false }
        if listings(for: tab).isEmpty && isFirstPageLoading(for: tab) { return true }
        if profile == nil, isLoading, !hasCompletedInitialLoad { return true }
        return false
    }

    func retryListings(for tab: ProfileListingTab, deps: AppDependencies) async {
        listingTabsStalled.remove(tab.rawValue)
        listingStallWatch.cancel(key: String(tab.rawValue))
        loadedListingTabs.remove(tab.rawValue)
        trimTasks[tab.rawValue]?.cancel()
        trimTasks[tab.rawValue] = nil
        backfillTasks[tab.rawValue]?.cancel()
        backfillTasks[tab.rawValue] = nil
        listingWindows[tab.rawValue] = nil
        await fetchListingsFirstPage(tab, deps: deps, force: true)
    }

    func refresh(
        deps: AppDependencies,
        force: Bool = true,
        activeTab: ProfileListingTab? = nil
    ) async {
        if !force,
           let last = lastSuccessfulRefreshAt,
           Date().timeIntervalSince(last) < profileStaleThresholdSeconds {
            await ensureListingsLoaded(for: activeTab ?? currentProfileTab(), deps: deps)
            return
        }
        let tab = activeTab ?? currentProfileTab()
        lastSelectedProfileTab = tab.rawValue
        let showBlocking = profile == nil
        if showBlocking {
            hasCompletedInitialLoad = false
            isLoading = true
        } else {
            requestScrollProfileToTop()
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
            hasCompletedInitialLoad = true
            if showBlocking {
                let initialTab = resolveInitialTabIndex()
                lastSelectedProfileTab = initialTab
                await fetchListingsFirstPage(
                    ProfileListingTab(rawValue: initialTab) ?? .active,
                    deps: deps,
                    force: true
                )
            } else {
                await reloadListingFeedOnRefresh(activeTab: tab, deps: deps)
            }
            await uxTask
        case .failure:
            loadError = true
            hasCompletedInitialLoad = true
        }
    }

    func onProfileTabSelected(_ tabIndex: Int, deps: AppDependencies) {
        lastSelectedProfileTab = tabIndex
        deps.uxTabTracker.onTabOpened(scope: "profile", tabKey: UxPersonalizationMapping.profileTabKey(from: tabIndex))
        let tab = ProfileListingTab(rawValue: tabIndex) ?? .active
        Task {
            await loadListingsForTab(tab, deps: deps, force: false)
            prefetchAdjacentProfileTabs(around: tab, deps: deps)
        }
    }

    /// Warm neighbor tabs in the background so swipe/tab tap does not show a single lazy tile.
    private func prefetchAdjacentProfileTabs(around tab: ProfileListingTab, deps: AppDependencies) {
        let order = orderedProfileTabIndices
        guard let center = order.firstIndex(of: tab.rawValue) else { return }
        let neighborIndices = [center - 1, center + 1].filter { order.indices.contains($0) }
        for idx in neighborIndices {
            guard let neighbor = ProfileListingTab(rawValue: order[idx]) else { continue }
            Task(priority: .utility) {
                await loadListingsForTab(neighbor, deps: deps, force: false)
            }
        }
    }

    /// Home journey / shortcuts — Android `requestOpenProfileTab` + `refresh(force = true)`.
    func requestWishlistTabFromHome(deps: AppDependencies) {
        requestOpenProfileTab(fromHome: .wishlist, deps: deps)
    }

    func requestInReviewTabFromHome(deps: AppDependencies) {
        requestOpenProfileTab(fromHome: .inReview, deps: deps)
    }

    func requestSellingTabFromHome(deps: AppDependencies) {
        requestOpenProfileTab(fromHome: .active, deps: deps)
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
        resetDisplayedIdentity()
        profile = nil
        sellingListings = []
        inReviewListings = []
        rejectedListings = []
        soldListings = []
        wishlistListings = []
        tabCounts = ProfileListingsSummary()
        loadedListingTabs = []
        listingTabsStalled = []
        listingStallWatch.cancelAll()
        tabPagination = [:]
        loadMoreTasks.values.forEach { $0.cancel() }
        loadMoreTasks = [:]
        backfillTasks.values.forEach { $0.cancel() }
        backfillTasks = [:]
        trimTasks.values.forEach { $0.cancel() }
        trimTasks = [:]
        listingWindows = [:]
        loadError = false
        lastSuccessfulRefreshAt = nil
        hasCompletedInitialLoad = false
        lastSelectedProfileTab = ProfileListingTab.active.rawValue
        isLoading = false
        isRefreshing = false
    }

    /// Clears header fields so a new account never shows the previous user's name/email while loading.
    private func resetDisplayedIdentity() {
        displayName = ""
        username = ""
        avatarUrl = ""
        coverImageUrl = ""
        bio = ""
        followerCount = 0
        followingCount = 0
        productCount = 0
        soldCount = 0
        aestheticCatalog = []
    }

    // MARK: - Private

    private struct ListingPagePayload {
        let items: [ListingFeedItem]
        let rawCount: Int
    }

    private struct ProfileTabPagination {
        var hasMore = true
        /// Next API offset (advance by raw page size, not deduped display count).
        var nextOffset = 0
        var isLoadingMore = false
        var isLoadingFirstPage = false
        var isReloading = false
        var fetchGeneration = 0
        var loadMoreCooldownUntil: Date?
    }

    private func pagination(for tab: ProfileListingTab) -> ProfileTabPagination {
        tabPagination[tab.rawValue] ?? ProfileTabPagination()
    }

    private func mutatePagination(for tab: ProfileListingTab, _ transform: (inout ProfileTabPagination) -> Void) {
        var state = pagination(for: tab)
        transform(&state)
        tabPagination[tab.rawValue] = state
    }

    private func currentProfileTab() -> ProfileListingTab {
        ProfileListingTab(rawValue: lastSelectedProfileTab) ?? .active
    }

    private func canLoadMore(for tab: ProfileListingTab) -> Bool {
        let p = pagination(for: tab)
        let listed = listings(for: tab)
        return p.hasMore
            && p.nextOffset > 0
            && !p.isLoadingMore
            && !p.isLoadingFirstPage
            && !p.isReloading
            && !isRefreshing
            && !listed.isEmpty
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

    private func reloadListingFeedOnRefresh(activeTab: ProfileListingTab, deps: AppDependencies) async {
        for tab in ProfileListingTab.allCases where tab != activeTab {
            loadedListingTabs.remove(tab.rawValue)
            mutatePagination(for: tab) { $0 = ProfileTabPagination() }
            trimTasks[tab.rawValue]?.cancel()
            trimTasks[tab.rawValue] = nil
            backfillTasks[tab.rawValue]?.cancel()
            backfillTasks[tab.rawValue] = nil
            listingWindows[tab.rawValue] = nil
            setListings([], for: tab)
        }
        await fetchListingsFirstPage(activeTab, deps: deps, force: true)
    }

    private func loadListingsForTab(_ tab: ProfileListingTab, deps: AppDependencies, force: Bool = false) async {
        if !force, loadedListingTabs.contains(tab.rawValue) { return }
        await fetchListingsFirstPage(tab, deps: deps, force: force)
    }

    private func fetchListingsFirstPage(
        _ tab: ProfileListingTab,
        deps: AppDependencies,
        force: Bool
    ) async {
        if force {
            mutatePagination(for: tab) { state in
                state.fetchGeneration += 1
                state.hasMore = true
                state.nextOffset = 0
            }
        } else {
            if loadedListingTabs.contains(tab.rawValue) { return }
            let p = pagination(for: tab)
            if p.isLoadingFirstPage || p.isReloading { return }
        }

        let generation = pagination(for: tab).fetchGeneration
        let hadItems = !listings(for: tab).isEmpty
        listingTabsStalled.remove(tab.rawValue)
        mutatePagination(for: tab) { state in
            if hadItems {
                state.isReloading = true
            } else {
                state.isLoadingFirstPage = true
            }
            state.isLoadingMore = false
        }
        scheduleListingStallWatch(for: tab)

        let result = await fetchListingsPage(tab: tab, offset: 0, deps: deps)
        guard generation == pagination(for: tab).fetchGeneration else { return }

        mutatePagination(for: tab) { state in
            state.isLoadingFirstPage = false
            state.isReloading = false
        }
        listingStallWatch.cancel(key: String(tab.rawValue))
        listingTabsStalled.remove(tab.rawValue)

        switch result {
        case .success(let page):
            loadedListingTabs.insert(tab.rawValue)
            setListings(page.items, for: tab)
            mutatePagination(for: tab) {
                $0.nextOffset = page.rawCount
                $0.hasMore = page.rawCount >= ProfileListingConstants.listingPageSize
            }
            FeedPerformance.log("Profile \(tab) first page -> items=\(page.items.count) hasMore=\(page.rawCount >= ProfileListingConstants.listingPageSize)")
            prefetchProfileImages(page.items)
            prefetchAdjacentProfileTabs(around: tab, deps: deps)
        case .failure:
            loadedListingTabs.remove(tab.rawValue)
            if !hadItems {
                setListings([], for: tab)
                mutatePagination(for: tab) { $0.hasMore = false }
            }
        }
    }

    private func loadMoreListings(for tab: ProfileListingTab, deps: AppDependencies) async {
        guard canLoadMore(for: tab) else { return }
        let now = Date()
        if let until = pagination(for: tab).loadMoreCooldownUntil, now < until { return }
        mutatePagination(for: tab) { $0.loadMoreCooldownUntil = now.addingTimeInterval(0.4) }

        let generation = pagination(for: tab).fetchGeneration
        let offset = pagination(for: tab).nextOffset
        guard offset > 0 else { return }

        mutatePagination(for: tab) { $0.isLoadingMore = true }
        defer { mutatePagination(for: tab) { $0.isLoadingMore = false } }

        let result = await fetchListingsPage(tab: tab, offset: offset, deps: deps)
        guard generation == pagination(for: tab).fetchGeneration else { return }

        switch result {
        case .success(let page):
            guard page.rawCount > 0 else {
                mutatePagination(for: tab) { $0.hasMore = false }
                return
            }
            var state = listingWindowState(for: tab)
            let added = state.window.appendUnique(page.items, knownIds: &state.knownIds)
            listingWindows[tab.rawValue] = state
            if added > 0 {
                syncListingsFromWindow(tab)
                prefetchProfileImages(Array(state.window.items.suffix(added)))
            }
            mutatePagination(for: tab) { state in
                state.nextOffset += page.rawCount
                state.hasMore = page.rawCount >= ProfileListingConstants.listingPageSize
            }
            FeedPerformance.log(
                "Profile \(tab) loadMore @\(offset) -> +\(added) window=\(listings(for: tab).count) logical=\(state.window.logicalStartIndex)"
            )
        case .failure:
            FeedPerformance.log("Profile \(tab) loadMore @\(offset) failed")
            break
        }
    }

    private func fetchListingsPage(
        tab: ProfileListingTab,
        offset: Int,
        deps: AppDependencies
    ) async -> Result<ListingPagePayload, Error> {
        let result: Result<[ListingFeedItem], Error>
        switch tab {
        case .wishlist:
            result = await deps.listingRepository.getWishlistListings(
                limit: ProfileListingConstants.listingPageSize,
                offset: offset
            )
        case .active:
            result = await deps.listingRepository.getMyListings(
                status: "active",
                limit: ProfileListingConstants.listingPageSize,
                offset: offset
            )
        case .inReview:
            result = await deps.listingRepository.getMyListings(
                status: "in_review",
                limit: ProfileListingConstants.listingPageSize,
                offset: offset
            )
        case .rejected:
            result = await deps.listingRepository.getMyListings(
                status: "rejected",
                limit: ProfileListingConstants.listingPageSize,
                offset: offset
            )
        case .sold:
            result = await deps.listingRepository.getMyListings(
                status: "sold",
                limit: ProfileListingConstants.listingPageSize,
                offset: offset
            )
        }
        switch result {
        case .success(let items):
            return .success(normalizeProfileListingsPage(items))
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Cap client work when the API returns more than `limit` — keeps masonry layout predictable.
    private func normalizeProfileListingsPage(_ rawPage: [ListingFeedItem]) -> ListingPagePayload {
        let items = Array(rawPage.prefix(ProfileListingConstants.listingPageSize))
        let deliveredCount = min(rawPage.count, ProfileListingConstants.listingPageSize)
        return ListingPagePayload(items: items, rawCount: deliveredCount)
    }

    private func setListings(_ items: [ListingFeedItem], for tab: ProfileListingTab) {
        var state = ProfileListingWindowState()
        state.knownIds = Set(items.map(\.id))
        state.window.reset(with: items)
        listingWindows[tab.rawValue] = state
        syncListingsFromWindow(tab)
    }

    private func syncListingsFromWindow(_ tab: ProfileListingTab) {
        let items = listingWindows[tab.rawValue]?.window.items ?? []
        switch tab {
        case .active: sellingListings = items
        case .inReview: inReviewListings = items
        case .rejected: rejectedListings = items
        case .sold: soldListings = items
        case .wishlist: wishlistListings = items
        }
    }

    private func listingWindowState(for tab: ProfileListingTab) -> ProfileListingWindowState {
        listingWindows[tab.rawValue] ?? ProfileListingWindowState()
    }

    private func applyScrollCompensation(_ signedDeltaY: CGFloat) {
        guard abs(signedDeltaY) > 0.5 else { return }
        listingScrollTrimSignedDeltaY = signedDeltaY
        listingScrollTrimToken += 1
    }

    private func prefetchProfileImages(_ items: [ListingFeedItem]) {
        let cap = min(items.count, ProfileListingConstants.imagePrefetchCap)
        guard cap > 0 else { return }
        FeedListingImagePrefetch.prefetch(items: Array(items.prefix(cap)))
    }

    private func scheduleDeferredWindowMaintenance(
        tab: ProfileListingTab,
        visibleIndex: Int,
        columnWidth: CGFloat,
        deps: AppDependencies
    ) {
        trimTasks[tab.rawValue]?.cancel()
        trimTasks[tab.rawValue] = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(240))
            guard !Task.isCancelled else { return }
            guard ProfileListingTab(rawValue: lastSelectedProfileTab) == tab else { return }
            guard !(scrollBoundary?.isUserInteracting ?? false) else { return }
            guard !isLoadingMoreListings(for: tab) else { return }

            var state = listingWindowState(for: tab)
            if let trim = state.window.trimFrontIfNeeded(
                visibleIndex: visibleIndex,
                columnWidth: columnWidth,
                policy: ProfileListingConstants.slidingWindowPolicy
            ) {
                listingWindows[tab.rawValue] = state
                syncListingsFromWindow(tab)
                applyScrollCompensation(-trim.scrollDeltaY)
                FeedPerformance.log(
                    "Profile \(tab) trim -\(trim.removedCount) window=\(state.window.items.count)"
                )
            }

            requestBackfillIfNeeded(
                tab: tab,
                visibleIndex: visibleIndex,
                columnWidth: columnWidth,
                deps: deps
            )
        }
    }

    private func requestBackfillIfNeeded(
        tab: ProfileListingTab,
        visibleIndex: Int,
        columnWidth: CGFloat,
        deps: AppDependencies
    ) {
        let policy = ProfileListingConstants.slidingWindowPolicy
        guard visibleIndex < policy.backfillVisibleThreshold else { return }
        var state = listingWindowState(for: tab)
        guard state.window.logicalStartIndex > 0 else { return }
        guard !state.isBackfilling else { return }
        guard backfillTasks[tab.rawValue] == nil else { return }
        guard !(scrollBoundary?.isUserInteracting ?? false) else { return }

        state.isBackfilling = true
        listingWindows[tab.rawValue] = state
        let logicalStart = state.window.logicalStartIndex
        let generation = pagination(for: tab).fetchGeneration

        backfillTasks[tab.rawValue] = Task { @MainActor in
            defer {
                var s = self.listingWindowState(for: tab)
                s.isBackfilling = false
                self.listingWindows[tab.rawValue] = s
                self.backfillTasks[tab.rawValue] = nil
            }
            let offset = max(0, logicalStart - ProfileListingConstants.listingPageSize)
            let result = await self.fetchListingsPage(tab: tab, offset: offset, deps: deps)
            guard generation == self.pagination(for: tab).fetchGeneration else { return }
            guard case .success(let page) = result, !page.items.isEmpty else { return }

            var s = self.listingWindowState(for: tab)
            guard let prepend = s.window.prependUnique(
                page.items,
                knownIds: &s.knownIds,
                columnWidth: columnWidth
            ) else { return }
            self.listingWindows[tab.rawValue] = s
            self.syncListingsFromWindow(tab)
            self.applyScrollCompensation(prepend.scrollDeltaY)
            self.prefetchProfileImages(Array(page.items.prefix(ProfileListingConstants.imagePrefetchCap)))
            FeedPerformance.log(
                "Profile \(tab) backfill @\(offset) +\(prepend.addedCount) window=\(s.window.items.count) logical=\(s.window.logicalStartIndex)"
            )
        }
    }

    private func scheduleListingStallWatch(for tab: ProfileListingTab) {
        let key = String(tab.rawValue)
        listingStallWatch.schedule(key: key) { [weak self] in
            guard let self else { return false }
            guard self.profile != nil else { return false }
            guard self.lastSelectedProfileTab == tab.rawValue
                || self.currentProfileTab() == tab else { return false }
            guard !self.loadedListingTabs.contains(tab.rawValue) else { return false }
            guard !self.isFirstPageLoading(for: tab) else { return false }
            guard self.listings(for: tab).isEmpty else { return false }
            return true
        } onStalled: { [weak self] in
            self?.listingTabsStalled.insert(tab.rawValue)
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

    private func requestOpenProfileTab(fromHome tab: ProfileListingTab, deps: AppDependencies) {
        requestOpenProfileTab(tab, scrollToGrid: true)
        Task { await refresh(deps: deps, force: true, activeTab: tab) }
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
                var state = listingWindowState(for: .wishlist)
                state.window.removeItems(withIds: [item.id], knownIds: &state.knownIds)
                listingWindows[ProfileListingTab.wishlist.rawValue] = state
                syncListingsFromWindow(.wishlist)
                tabCounts.wishlist = max(0, tabCounts.wishlist - 1)
            } else if saved {
                let patched = snapshot.applyingSaveToggle(true)
                var state = listingWindowState(for: .wishlist)
                if state.window.insertUniqueAtTop(patched, knownIds: &state.knownIds) {
                    listingWindows[ProfileListingTab.wishlist.rawValue] = state
                    syncListingsFromWindow(.wishlist)
                    tabCounts.wishlist += 1
                }
            }
            deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
        case .failure(let error):
            patchListing(item.id) { _ in snapshot }
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        }
    }

    private func patchListing(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        for tab in ProfileListingTab.allCases {
            guard var state = listingWindows[tab.rawValue] else { continue }
            state.window.mapItems { $0.id == id ? transform($0) : $0 }
            listingWindows[tab.rawValue] = state
            syncListingsFromWindow(tab)
        }
    }
}
