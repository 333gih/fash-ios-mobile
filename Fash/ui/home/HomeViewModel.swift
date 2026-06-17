import Foundation
import Observation

private enum HomeFeedConstants {
    static let followPageSize = 20
    static let huntTodayLimit = 12
    static let tabLoadMorePageSize = 20
    static let staleThreshold: TimeInterval = 60
}

private struct HomeTabFeedState {
    var hasMore = false
    var isLoadingMore = false
}

@Observable
@MainActor
final class HomeViewModel {
    var isShellLoading = false
    var isRefreshing = false
    var items: [ListingFeedItem] = []
    var errorMessage: String?
    var selectedFeedTabKey = HomeFeedTabKeys.huntToday
    var featuredSellers: [FeaturedSellerItem] = []
    var featuredSellersLoading = false
    var promoSlides: [AppAdvertisingSlideItem] = []
    var homeUxPersonalization = HomeUxPersonalization()
    var tabsLoading: Set<String> = []
    var tabsLoadError: Set<String> = []
    var tabsLoadStalled: Set<String> = []
    var followingHasMore = false
    var isLoadingMoreFollowing = false
    var buyerStats = BuyerHomeStats()
    var showSizingBanner = false
    private(set) var homeScrollToTopToken = 0
    /// Tab tap/swipe — scroll to pinned tab row + feed start (not full header).
    private(set) var homeScrollToFeedTopToken = 0
    private(set) var homePinnedScrollResetToken = 0
    private(set) var homeTabBarScrollToken = 0
    var homeFeedTrimToken = 0
    private(set) var homeFeedTrimSignedDeltaY: CGFloat = 0

    private var sections = HomeRecommendationSections()
    private var followingWindow = FeedSlidingWindow()
    private var followingItemIds = Set<String>()
    private var followingNextCursor: String?
    private var loadedTabs: Set<String> = []
    private var recommendationSectionsFetched = false
    private var tabLoadTasks: [String: Task<Void, Never>] = [:]
    private let tabStallWatch = FeedLoadStallWatch()
    private var homeUxApplied = false
    private var lastSuccessfulRefreshAt: Date?
    private var lastFollowFeedLoadMoreAt: Date?
    private var followingDuplicatePageCount = 0
    private var followingTrimTask: Task<Void, Never>?
    private var tabFeedState: [String: HomeTabFeedState] = [:]
    private var sectionLoadMoreTasks: [String: Task<Void, Never>] = [:]

    /// Scroll boundary from [HomeFeedScrollCoordinator] — gates Following pagination while scrolling up.
    @ObservationIgnored
    var homeScrollBoundary: HomeFeedScrollBoundary?

    var selectedFeedTab: HomeFeedTab {
        HomeFeedTab(rawValue: selectedFeedTabKey) ?? .huntToday
    }

    func orderedTabs(isGuestMode: Bool) -> [HomeFeedTab] {
        UxPersonalizationMapping.orderedHomeFeedTabs(
            isGuestBrowse: isGuestMode,
            tabOrderKeys: homeUxPersonalization.tabOrder
        )
    }

    func isTabLoading(_ tab: HomeFeedTab) -> Bool {
        tabsLoading.contains(tab.rawValue)
    }

    func isTabLoadError(_ tab: HomeFeedTab) -> Bool {
        tabsLoadError.contains(tab.rawValue)
    }

    func isTabLoadStalled(_ tab: HomeFeedTab) -> Bool {
        tabsLoadStalled.contains(tab.rawValue)
    }

    func hasMore(for tab: HomeFeedTab) -> Bool {
        if tab == .following { return followingHasMore }
        return tabFeedState[tab.rawValue]?.hasMore ?? false
    }

    func isLoadingMore(for tab: HomeFeedTab) -> Bool {
        if tab == .following { return isLoadingMoreFollowing }
        return tabFeedState[tab.rawValue]?.isLoadingMore ?? false
    }

    func loadMore(deps: AppDependencies, isGuestMode: Bool, fromScrollEdge: Bool = false) {
        let tab = selectedFeedTab
        if tab == .following {
            loadMoreFollowing(deps: deps, isGuestMode: isGuestMode, fromScrollEdge: fromScrollEdge)
            return
        }
        if isGuestMode && tab.requiresAuth { return }
        loadMoreSectionTab(tab, deps: deps, isGuestMode: isGuestMode)
    }

    /// Tile prefetch + sliding-window trim for Following; tile prefetch for discovery tabs.
    func notifyHomeCellVisible(
        index: Int,
        columnWidth: CGFloat,
        deps: AppDependencies,
        isGuestMode: Bool
    ) {
        let tab = selectedFeedTab
        if tab == .following {
            notifyFollowingCellVisible(
                index: index,
                columnWidth: columnWidth,
                deps: deps,
                isGuestMode: isGuestMode
            )
            return
        }
        guard !isShellLoading, !isRefreshing, !isTabLoading(tab) else { return }
        guard FeedPaginationPolicy.shouldPrefetchNextPage(
            appearedIndex: index,
            totalCount: items.count
        ) else { return }
        loadMore(deps: deps, isGuestMode: isGuestMode)
    }

    /// Main tab Home visible — reload default feed tab if UI is empty without an active load.
    func ensureSelectedFeedTabLoaded(deps: AppDependencies, isGuestMode: Bool) {
        normalizeSelectedFeedTab(isGuestMode: isGuestMode, deps: deps)
        let tab = selectedFeedTab
        if isGuestMode && tab.requiresAuth { return }
        if items.isEmpty, !isTabLoading(tab), !isTabLoadError(tab) {
            ensureTabLoaded(tab, deps: deps, isGuestMode: isGuestMode, force: true)
        } else if !items.isEmpty {
            syncItemsForSelectedTab()
        }
    }

    func onGuestBrowseEntered(deps: AppDependencies) {
        deps.uxTabTracker.closeActiveTab()
        deps.feedEventReporter.flush()
        deps.feedEventReporter.clearPending()
        homeUxApplied = false
        homeUxPersonalization = HomeUxPersonalization()
        invalidateAllTabFeeds()
        selectedFeedTabKey = HomeFeedTabKeys.huntToday
        items = []
        errorMessage = nil
        featuredSellers = []
        featuredSellersLoading = false
        followingWindow.reset(with: [])
        followingItemIds = []
        followingNextCursor = nil
        followingHasMore = false
        followingDuplicatePageCount = 0
        buyerStats = BuyerHomeStats()
        showSizingBanner = false
    }

    func clearCachesForSignedOutUser(deps: AppDependencies) {
        deps.uxTabTracker.closeActiveTab()
        deps.uxTabTracker.flush()
        deps.feedEventReporter.flush()
        deps.feedEventReporter.clearPending()
        onGuestBrowseEntered(deps: deps)
        isShellLoading = false
        isRefreshing = false
        isLoadingMoreFollowing = false
        buyerStats = BuyerHomeStats()
        showSizingBanner = false
        HomeSizingBannerPreference.reset()
        lastSuccessfulRefreshAt = nil
    }

    func selectFeedTab(_ tab: HomeFeedTab, deps: AppDependencies, isGuestMode: Bool) {
        if selectedFeedTab == tab {
            requestScrollHomeToTop()
            ensureSelectedFeedTabLoaded(deps: deps, isGuestMode: isGuestMode)
            return
        }
        openFeedTab(tab, deps: deps, isGuestMode: isGuestMode)
    }

    private func openFeedTab(_ tab: HomeFeedTab, deps: AppDependencies, isGuestMode: Bool) {
        deps.uxTabTracker.onTabOpened(scope: "home", tabKey: UxPersonalizationMapping.uxTabKey(for: tab))
        selectedFeedTabKey = tab.rawValue
        syncVisibleItemsForTab(tab)
        requestScrollHomeFeedToTop()
        ensureTabLoaded(tab, deps: deps, isGuestMode: isGuestMode)
        homeTabBarScrollToken &+= 1
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard selectedFeedTab == tab else { return }
            prefetchAdjacentTabs(around: tab, deps: deps, isGuestMode: isGuestMode)
        }
    }

    /// Bottom-nav re-tap / same-tab reselect — scroll to full header top (Android `requestScrollHomeToTop`).
    func requestScrollHomeToTop() {
        homeScrollToTopToken &+= 1
    }

    /// Horizontal swipe or different tab tap — align pinned tabs + first rows of that tab.
    func requestScrollHomeFeedToTop() {
        homeScrollToFeedTopToken &+= 1
    }

    func normalizeSelectedFeedTab(isGuestMode: Bool, deps: AppDependencies) {
        if isGuestMode {
            if selectedFeedTab != .huntToday {
                deps.uxTabTracker.closeActiveTab()
                selectedFeedTabKey = HomeFeedTabKeys.huntToday
                syncItemsForSelectedTab()
            }
            return
        }
        let allowed = HomeFeedTab.tabsFor(isGuestBrowse: false)
        if !allowed.contains(selectedFeedTab) {
            resetToHuntToday(deps: deps, isGuestMode: isGuestMode, forceReload: true)
        }
    }

    /// Launch gate — prefetch active tab + shell chrome while the waiting screen is visible.
    func awaitLaunchReady(
        deps: AppDependencies,
        isGuestMode: Bool,
        launchProgress: LaunchWaitingProgress? = nil
    ) async {
        normalizeSelectedFeedTab(isGuestMode: isGuestMode, deps: deps)
        await awaitSelectedFeedTab(deps: deps, isGuestMode: isGuestMode, force: true)
        launchProgress?.completeHomeStep()
        await loadShellEnrichment(deps: deps, isGuestMode: isGuestMode, launchProgress: launchProgress)
        prefetchAdjacentTabs(around: selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
        lastSuccessfulRefreshAt = Date()
    }

    func loadShell(deps: AppDependencies, isGuestMode: Bool, skipIfFresh: Bool = false, launchProgress: LaunchWaitingProgress? = nil) async {
        if skipIfFresh, isLaunchShellFresh {
            normalizeSelectedFeedTab(isGuestMode: isGuestMode, deps: deps)
            ensureTabLoaded(selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
            if featuredSellers.isEmpty, !featuredSellersLoading {
                await loadFeaturedSellers(deps: deps, isGuestMode: isGuestMode)
            }
            return
        }
        isShellLoading = true
        errorMessage = nil
        defer { isShellLoading = false }

        normalizeSelectedFeedTab(isGuestMode: isGuestMode, deps: deps)
        await awaitSelectedFeedTab(deps: deps, isGuestMode: isGuestMode, force: true)
        launchProgress?.completeHomeStep()
        await loadShellEnrichment(deps: deps, isGuestMode: isGuestMode, launchProgress: launchProgress)
        lastSuccessfulRefreshAt = Date()
    }

    private func scheduleShellEnrichment(deps: AppDependencies, isGuestMode: Bool) {
        Task { await loadShellEnrichment(deps: deps, isGuestMode: isGuestMode, launchProgress: nil) }
    }

    private func loadShellEnrichment(
        deps: AppDependencies,
        isGuestMode: Bool,
        launchProgress: LaunchWaitingProgress? = nil
    ) async {
        async let sellersTask: Void = loadFeaturedSellers(deps: deps, isGuestMode: isGuestMode)
        async let slidesResult = deps.advertisingRepository.getSlides(publicBrowse: isGuestMode)

        if !isGuestMode {
            async let ux: Void = {
                await loadUxPersonalization(deps: deps, isGuestMode: isGuestMode)
                await MainActor.run { launchProgress?.completeHomeStep() }
            }()
            async let sections: Void = {
                _ = await prefetchRecommendationSections(deps: deps, isGuestMode: isGuestMode)
                await MainActor.run { launchProgress?.completeHomeStep() }
            }()
            async let stats: Void = {
                _ = await loadBuyerHomeStats(deps: deps, isGuestMode: isGuestMode)
                await MainActor.run { launchProgress?.completeHomeStep() }
            }()
            async let sizing: Void = {
                await refreshSizingBannerState(deps: deps, isGuestMode: isGuestMode)
                await MainActor.run { launchProgress?.completeHomeStep() }
            }()
            _ = await (ux, sections, stats, sizing, sellersTask)
        } else {
            await sellersTask
        }
        launchProgress?.completeHomeStep()

        if case .success(let slides) = await slidesResult {
            promoSlides = slides.items
        }
        launchProgress?.completeHomeStep()

        prefetchAdjacentTabs(around: selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
        launchProgress?.completeHomeStep()
    }

    func loadFeaturedSellers(deps: AppDependencies, isGuestMode: Bool) async {
        // Stale-while-revalidate — keep "Shop nên ghé" visible during nav re-tap / pull-to-refresh.
        let shouldShowLoadingShell = featuredSellers.isEmpty
        if shouldShowLoadingShell {
            featuredSellersLoading = true
        }
        defer {
            if shouldShowLoadingShell {
                featuredSellersLoading = false
            }
        }
        switch await fetchFeaturedSellersWithRetry(deps: deps, isGuestMode: isGuestMode) {
        case .success(let sellers):
            featuredSellers = sellers
        case .failure:
            break
        }
    }

    private func fetchFeaturedSellersWithRetry(
        deps: AppDependencies,
        isGuestMode: Bool
    ) async -> Result<[FeaturedSellerItem], Error> {
        func fetchOnce() async -> Result<[FeaturedSellerItem], Error> {
            await deps.searchRepository.getFeaturedSellers(limit: 12, publicBrowse: isGuestMode)
        }
        var result = await fetchOnce()
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(400))
            result = await fetchOnce()
        }
        return result
    }

    private func awaitSelectedFeedTab(
        deps: AppDependencies,
        isGuestMode: Bool,
        force: Bool
    ) async {
        let tab = selectedFeedTab
        if isGuestMode && tab.requiresAuth { return }
        beginTabLoad(tab)
        tabLoadTasks[tab.rawValue]?.cancel()
        setTabError(tab, false)
        let ok = await loadTab(tab, deps: deps, isGuestMode: isGuestMode, force: force)
        finishTabLoad(tab, succeeded: ok)
        tabLoadTasks[tab.rawValue] = nil
    }

    func pullToRefresh(deps: AppDependencies, isGuestMode: Bool = false) async {
        isRefreshing = true
        defer { isRefreshing = false }
        let tabToReload = selectedFeedTab

        // Pinterest-style: refresh feed first so spinner dismisses when listings update; chrome loads after.
        await reloadFeedTab(tabToReload, deps: deps, isGuestMode: isGuestMode)
        if tabToReload == selectedFeedTab {
            syncItemsForSelectedTab()
        }
        lastSuccessfulRefreshAt = Date()

        Task { @MainActor in
            async let sellers: Void = loadFeaturedSellers(deps: deps, isGuestMode: isGuestMode)
            async let slidesResult = deps.advertisingRepository.getSlides(publicBrowse: isGuestMode)
            if !isGuestMode {
                async let stats: Void = loadBuyerHomeStats(deps: deps, isGuestMode: isGuestMode)
                async let sizing: Void = refreshSizingBannerState(deps: deps, isGuestMode: isGuestMode)
                _ = await (stats, sizing)
            }
            _ = await sellers
            if case .success(let slides) = await slidesResult {
                promoSlides = slides.items
            }
            try? await Task.sleep(for: .milliseconds(220))
            guard selectedFeedTab == tabToReload else { return }
            prefetchAdjacentTabs(around: selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
        }
    }

    func retryTab(_ tab: HomeFeedTab, deps: AppDependencies, isGuestMode: Bool) {
        tabsLoadStalled.remove(tab.rawValue)
        loadedTabs.remove(tab.rawValue)
        if HomeFeedTab.recommendationSectionTabs.contains(tab) {
            recommendationSectionsFetched = false
            HomeFeedTab.recommendationSectionTabs.forEach { loadedTabs.remove($0.rawValue) }
        }
        ensureTabLoaded(tab, deps: deps, isGuestMode: isGuestMode, force: true)
    }

    func loadMoreFollowing(deps: AppDependencies, isGuestMode: Bool, fromScrollEdge: Bool = false) {
        guard !isGuestMode else { return }
        guard selectedFeedTab == .following else { return }
        guard !isLoadingMoreFollowing, followingHasMore else { return }
        guard !isShellLoading, !isRefreshing, !isTabLoading(.following) else { return }
        if !fromScrollEdge {
            guard homeScrollBoundary?.allowsFollowingLoadMore ?? true else { return }
        }
        if let last = lastFollowFeedLoadMoreAt, Date().timeIntervalSince(last) < 0.9 { return }
        lastFollowFeedLoadMoreAt = Date()
        isLoadingMoreFollowing = true
        let cursor = followingNextCursor
        let offsetFallback = cursor == nil ? followingWindow.items.count : nil
        Task {
            defer { isLoadingMoreFollowing = false }
            let result = await FeedPerformance.measure("Home following loadMore cursor=\(cursor ?? "offset:\(offsetFallback ?? 0)")") {
                await fetchFollowingPage(deps: deps, cursor: cursor, offsetFallback: offsetFallback)
            }
            guard case .success(let page) = result else { return }
            followingHasMore = page.hasMore
            followingNextCursor = page.nextCursor
            if page.items.isEmpty {
                followingHasMore = false
                followingDuplicatePageCount = 0
                if selectedFeedTab == .following { syncItemsForSelectedTab() }
                return
            }
            let added = followingWindow.appendUnique(page.items, knownIds: &followingItemIds)
            guard added > 0 else {
                followingDuplicatePageCount += 1
                if followingDuplicatePageCount >= 2 || page.items.isEmpty {
                    followingHasMore = false
                }
                if selectedFeedTab == .following { syncItemsForSelectedTab() }
                return
            }
            followingDuplicatePageCount = 0
            if selectedFeedTab == .following {
                syncItemsForSelectedTab()
            }
            FeedPerformance.log("Home following append +\(added) window=\(followingWindow.items.count) hasMore=\(followingHasMore)")
        }
    }

    /// Tile prefetch + sliding-window trim (idle only — never while finger is on screen).
    func notifyFollowingCellVisible(
        index: Int,
        columnWidth: CGFloat,
        deps: AppDependencies,
        isGuestMode: Bool
    ) {
        guard selectedFeedTab == .following else { return }
        requestLoadMoreFollowingIfNeeded(
            appearedIndex: index,
            deps: deps,
            isGuestMode: isGuestMode
        )
        scheduleFollowingWindowTrim(visibleIndex: index, columnWidth: columnWidth)
    }

    private func scheduleFollowingWindowTrim(visibleIndex: Int, columnWidth: CGFloat) {
        followingTrimTask?.cancel()
        followingTrimTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            guard !Task.isCancelled else { return }
            guard selectedFeedTab == .following else { return }
            guard let boundary = homeScrollBoundary, !boundary.isUserInteracting else { return }
            guard let trim = followingWindow.trimFrontIfNeeded(
                visibleIndex: visibleIndex,
                columnWidth: columnWidth,
                policy: .homeFollowing
            ) else { return }
            syncItemsForSelectedTab()
            homeFeedTrimSignedDeltaY = -trim.scrollDeltaY
            homeFeedTrimToken += 1
            FeedPerformance.log(
                "Home following trim -\(trim.removedCount) window=\(followingWindow.items.count)"
            )
        }
    }

    /// Tile-anchored pagination — same policy as Explore (within 8 rows of end).
    func requestLoadMoreFollowingIfNeeded(
        appearedIndex: Int,
        deps: AppDependencies,
        isGuestMode: Bool
    ) {
        guard selectedFeedTab == .following else { return }
        guard !isShellLoading, !isRefreshing, !isTabLoading(.following) else { return }
        guard FeedPaginationPolicy.shouldPrefetchNextPage(
            appearedIndex: appearedIndex,
            totalCount: followingWindow.items.count
        ) else { return }
        loadMoreFollowing(deps: deps, isGuestMode: isGuestMode)
    }

    /// Brand footer only when the active tab finished loading and has no more pages.
    func showsHomeBrandFooter(isGuestMode: Bool) -> Bool {
        let tab = selectedFeedTab
        if isGuestMode && tab.requiresAuth { return false }
        if items.isEmpty { return false }
        if isShellLoading || isTabLoading(tab) { return false }
        if tab == .following {
            return !followingHasMore && !isLoadingMoreFollowing
        }
        return hasMore(for: tab) == false && !isLoadingMore(for: tab) && loadedTabs.contains(tab.rawValue)
    }

    func recordView(item: ListingFeedItem, position: Int, surface: String, deps: AppDependencies) {
        deps.feedEventReporter.impression(listingId: item.id, surface: surface, position: position)
        Task { _ = await deps.listingRepository.recordView(listingId: item.id) }
    }

    func recordDwell(item: ListingFeedItem, surface: String, position: Int, dwellMs: Int, deps: AppDependencies) {
        guard dwellMs >= 800 else { return }
        deps.feedEventReporter.dwell(listingId: item.id, surface: surface, position: position, dwellMs: dwellMs)
    }

    func reportListingClick(item: ListingFeedItem, surface: String, position: Int, deps: AppDependencies) {
        deps.feedEventReporter.click(listingId: item.id, surface: surface, position: position)
    }

    func dismissSizingBanner() {
        HomeSizingBannerPreference.markDismissed()
        showSizingBanner = false
    }

    func refreshSizingBannerAfterProfileSave(deps: AppDependencies, isGuestMode: Bool) {
        Task { await refreshSizingBannerState(deps: deps, isGuestMode: isGuestMode) }
    }

    func toggleLike(_ item: ListingFeedItem, surface: String, position: Int, deps: AppDependencies) {
        let snapshot = item
        guard deps.listingEngagement.beginLikeToggle(listingId: item.id) else { return }
        patchListingInFeeds(item.id) { _ in snapshot.toggledLike }
        Task {
            defer { deps.listingEngagement.endLikeToggle(listingId: item.id) }
            switch await deps.listingRepository.toggleLike(listingId: item.id) {
            case .success(let liked):
                patchListingInFeeds(item.id) { _ in snapshot.applyingLikeToggle(liked) }
                if liked {
                    deps.feedEventReporter.like(listingId: item.id, surface: surface, position: position)
                }
                deps.showSnackbar(FeedEngagementFeedback.likeMessage(liked: liked))
            case .failure(let error):
                patchListingInFeeds(item.id) { _ in snapshot }
                deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
            }
        }
    }

    func toggleSave(_ item: ListingFeedItem, surface: String, position: Int, deps: AppDependencies, isGuestMode: Bool) {
        let snapshot = item
        guard deps.listingEngagement.beginSaveToggle(listingId: item.id) else { return }
        patchListingInFeeds(item.id) { _ in snapshot.toggledSave }
        Task {
            defer { deps.listingEngagement.endSaveToggle(listingId: item.id) }
            switch await deps.listingRepository.toggleSave(
                listingId: item.id,
                currentlySaved: snapshot.isSaved
            ) {
            case .success(let saved):
                patchListingInFeeds(item.id) { _ in snapshot.applyingSaveToggle(saved) }
                if saved {
                    deps.feedEventReporter.save(listingId: item.id, surface: surface, position: position)
                }
                deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
                if !isGuestMode {
                    Task { await loadBuyerHomeStats(deps: deps, isGuestMode: false) }
                }
            case .failure(let error):
                patchListingInFeeds(item.id) { _ in snapshot }
                deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
            }
        }
    }

    // MARK: - Private

    /// Shell was prefetched on the launch waiting screen — skip duplicate network on first Home appear.
    private var isLaunchShellFresh: Bool {
        guard let lastSuccessfulRefreshAt else { return false }
        guard Date().timeIntervalSince(lastSuccessfulRefreshAt) < 120 else { return false }
        return !items.isEmpty || recommendationSectionsFetched
    }

    private func invalidateAllTabFeeds() {
        tabLoadTasks.values.forEach { $0.cancel() }
        tabLoadTasks.removeAll()
        loadedTabs.removeAll()
        recommendationSectionsFetched = false
        sections = HomeRecommendationSections()
        followingWindow.reset(with: [])
        followingItemIds = []
        followingNextCursor = nil
        followingHasMore = false
        followingDuplicatePageCount = 0
        tabFeedState = [:]
        sectionLoadMoreTasks.values.forEach { $0.cancel() }
        sectionLoadMoreTasks = [:]
        tabsLoading = []
        tabsLoadError = []
        tabsLoadStalled = []
        tabStallWatch.cancelAll()
        syncItemsForSelectedTab()
    }

    private func resetToHuntToday(deps: AppDependencies, isGuestMode: Bool, forceReload: Bool) {
        let switched = selectedFeedTab != .huntToday
        if switched {
            deps.uxTabTracker.closeActiveTab()
            selectedFeedTabKey = HomeFeedTabKeys.huntToday
            syncItemsForSelectedTab()
        }
        if forceReload || switched {
            ensureTabLoaded(.huntToday, deps: deps, isGuestMode: isGuestMode, force: true)
        }
    }

    private func ensureTabLoaded(
        _ tab: HomeFeedTab,
        deps: AppDependencies,
        isGuestMode: Bool,
        force: Bool = false
    ) {
        if isGuestMode && tab.requiresAuth { return }
        if force {
            tabLoadTasks[tab.rawValue]?.cancel()
            tabLoadTasks[tab.rawValue] = nil
        }
        if !force && loadedTabs.contains(tab.rawValue) {
            if tab == selectedFeedTab {
                syncItemsForSelectedTab()
            }
            return
        }
        if tabLoadTasks[tab.rawValue] != nil { return }
        if !force && tab == .huntToday && recommendationSectionsFetched && !sections.huntToday.isEmpty {
            loadedTabs.insert(tab.rawValue)
            syncItemsForSelectedTab()
            return
        }
        if !force && HomeFeedTab.recommendationSectionTabs.contains(tab) && recommendationSectionsFetched {
            loadedTabs.insert(tab.rawValue)
            syncItemsForSelectedTab()
            return
        }

        beginTabLoad(tab)
        if tab == selectedFeedTab {
            syncItemsForSelectedTab()
        }
        tabLoadTasks[tab.rawValue] = Task {
            setTabError(tab, false)
            let ok = await loadTab(tab, deps: deps, isGuestMode: isGuestMode, force: force)
            finishTabLoad(tab, succeeded: ok)
            tabLoadTasks[tab.rawValue] = nil
        }
    }

    private func prefetchAdjacentTabs(around tab: HomeFeedTab, deps: AppDependencies, isGuestMode: Bool) {
        let ux = homeUxPersonalization
        let tabs = orderedTabs(isGuestMode: isGuestMode)
        let prefetchKeys = ux.prefetchTabs.compactMap { UxPersonalizationMapping.homeFeedTab(from: $0) }.filter { tabs.contains($0) }
        let targets: [HomeFeedTab]
        if !prefetchKeys.isEmpty {
            targets = prefetchKeys.filter { $0 != tab }.prefix(2).map { $0 }
        } else if let idx = tabs.firstIndex(of: tab) {
            targets = [tabs[safe: idx - 1], tabs[safe: idx + 1]].compactMap { $0 }
        } else {
            targets = []
        }
        targets.forEach { ensureTabLoaded($0, deps: deps, isGuestMode: isGuestMode) }
    }

    private func loadTab(
        _ tab: HomeFeedTab,
        deps: AppDependencies,
        isGuestMode: Bool,
        force: Bool
    ) async -> Bool {
        switch tab {
        case .huntToday:
            return await loadHuntTodayTab(deps: deps, isGuestMode: isGuestMode, force: force)
        case .following:
            return await loadFollowingTab(deps: deps, isGuestMode: isGuestMode, force: force)
        case .forYou, .stylePicks, .similarSaved, .seasonalNearYou:
            return await loadRecommendationSections(deps: deps, isGuestMode: isGuestMode, force: force)
        }
    }

    private func loadUxPersonalization(deps: AppDependencies, isGuestMode: Bool) async {
        guard !isGuestMode else { return }
        let uid = deps.authSessionStore.read()?.userId
        if let local = UxPersonalizationLocalStore.readHomeDefaultTab(userId: uid),
           let tab = UxPersonalizationMapping.homeFeedTab(from: local),
           !homeUxApplied {
            applyPreferredHomeTab(tab, deps: deps, isGuestMode: isGuestMode)
        }
        let result = await deps.recommendationRepository.uxPersonalization(
            clientHour: UxPersonalizationLocalStore.currentClientHour()
        )
        guard case .success(let bundle) = result else { return }
        let previousOrder = homeUxPersonalization.tabOrder
        homeUxPersonalization = bundle.home
        if previousOrder != bundle.home.tabOrder {
            homeTabBarScrollToken &+= 1
        }
        UxPersonalizationLocalStore.writeHomeDefaultTab(userId: uid, tabKey: bundle.home.defaultTabKey)
        if let tab = UxPersonalizationMapping.homeFeedTab(from: bundle.home.defaultTabKey) {
            applyPreferredHomeTab(tab, deps: deps, isGuestMode: isGuestMode)
        }
        bundle.home.prefetchTabs
            .compactMap { UxPersonalizationMapping.homeFeedTab(from: $0) }
            .forEach { ensureTabLoaded($0, deps: deps, isGuestMode: isGuestMode) }
    }

    private func applyPreferredHomeTab(_ tab: HomeFeedTab, deps: AppDependencies, isGuestMode: Bool) {
        if isGuestMode && tab.requiresAuth { return }
        guard HomeFeedTab.tabsFor(isGuestBrowse: isGuestMode).contains(tab) else { return }
        if homeUxApplied && selectedFeedTab == tab { return }
        homeUxApplied = true
        selectedFeedTabKey = tab.rawValue
        syncVisibleItemsForTab(tab)
        homeTabBarScrollToken &+= 1
        deps.uxTabTracker.onTabOpened(scope: "home", tabKey: UxPersonalizationMapping.uxTabKey(for: tab))
        ensureTabLoaded(tab, deps: deps, isGuestMode: isGuestMode, force: !loadedTabs.contains(tab.rawValue))
    }

    private func beginTabLoad(_ tab: HomeFeedTab) {
        tabsLoadStalled.remove(tab.rawValue)
        setTabLoading(tab, true)
        scheduleTabStallWatch(for: tab)
    }

    private func finishTabLoad(_ tab: HomeFeedTab, succeeded: Bool) {
        tabStallWatch.cancel(key: tab.rawValue)
        tabsLoadStalled.remove(tab.rawValue)
        if succeeded {
            loadedTabs.insert(tab.rawValue)
            if HomeFeedTab.recommendationSectionTabs.contains(tab) {
                HomeFeedTab.recommendationSectionTabs.forEach { loadedTabs.insert($0.rawValue) }
            }
            if tab == selectedFeedTab {
                syncItemsForSelectedTab()
            }
        } else {
            setTabError(tab, true)
        }
        setTabLoading(tab, false)
    }

    private func scheduleTabStallWatch(for tab: HomeFeedTab) {
        let key = tab.rawValue
        tabStallWatch.schedule(key: key) { [weak self] in
            guard let self else { return false }
            guard self.selectedFeedTab == tab else { return false }
            guard !self.loadedTabs.contains(key) else { return false }
            guard !self.tabsLoading.contains(key) else { return false }
            guard self.items.isEmpty else { return false }
            return true
        } onStalled: { [weak self] in
            self?.tabsLoadStalled.insert(key)
        }
    }

    private func sectionLimit(for tab: HomeFeedTab, fallback: Int) -> Int {
        homeUxPersonalization.sectionLimits[UxPersonalizationMapping.uxTabKey(for: tab)] ?? fallback
    }

    private func huntTodaySizingMode() -> String? {
        ExploreSizingPreference.activeSizingModeForRecommendations()
    }

    private func prefetchRecommendationSections(deps: AppDependencies, isGuestMode: Bool) async -> Bool {
        guard !isGuestMode else { return false }
        return await loadRecommendationSections(deps: deps, isGuestMode: isGuestMode, force: false)
    }

    private func reloadFeedTab(_ tab: HomeFeedTab, deps: AppDependencies, isGuestMode: Bool) async {
        tabLoadTasks[tab.rawValue]?.cancel()
        let showTabSpinner = !isRefreshing
        if showTabSpinner {
            setTabLoading(tab, true)
            setTabError(tab, false)
        }
        let ok = await loadTab(tab, deps: deps, isGuestMode: isGuestMode, force: true)
        if ok {
            loadedTabs.insert(tab.rawValue)
            if HomeFeedTab.recommendationSectionTabs.contains(tab) {
                HomeFeedTab.recommendationSectionTabs.forEach { loadedTabs.insert($0.rawValue) }
            }
            if tab == selectedFeedTab {
                syncItemsForSelectedTab()
            }
        } else if showTabSpinner {
            setTabError(tab, true)
        }
        if showTabSpinner {
            setTabLoading(tab, false)
        }
        tabLoadTasks[tab.rawValue] = nil
    }

    private func loadHuntTodayTab(deps: AppDependencies, isGuestMode: Bool, force: Bool) async -> Bool {
        if !force && loadedTabs.contains(HomeFeedTabKeys.huntToday) { return true }
        if !isGuestMode && recommendationSectionsFetched && !sections.huntToday.isEmpty {
            if selectedFeedTab == .huntToday { syncItemsForSelectedTab() }
            return true
        }
        let result = await deps.recommendationRepository.exploreListings(
            publicBrowse: isGuestMode,
            limit: sectionLimit(for: .huntToday, fallback: HomeFeedConstants.huntTodayLimit),
            offset: 0,
            sizingMode: huntTodaySizingMode(),
            surface: HomeFeedTab.huntToday.analyticsSurface
        )
        guard case .success(let loaded) = result else { return false }
        sections.huntToday = loaded
        let limit = sectionLimit(for: .huntToday, fallback: HomeFeedConstants.huntTodayLimit)
        setTabHasMore(.huntToday, loaded.count >= limit)
        if selectedFeedTab == .huntToday { syncItemsForSelectedTab() }
        return true
    }

    private func loadMoreSectionTab(
        _ tab: HomeFeedTab,
        deps: AppDependencies,
        isGuestMode: Bool
    ) {
        guard hasMore(for: tab), !isLoadingMore(for: tab) else { return }
        guard !isShellLoading, !isRefreshing, !isTabLoading(tab) else { return }
        guard sectionLoadMoreTasks[tab.rawValue] == nil else { return }

        setTabLoadingMore(tab, true)
        let offset = itemsForTab(tab).count
        sectionLoadMoreTasks[tab.rawValue] = Task {
            defer {
                sectionLoadMoreTasks[tab.rawValue] = nil
                setTabLoadingMore(tab, false)
            }
            let result = await deps.recommendationRepository.exploreListings(
                publicBrowse: isGuestMode,
                limit: HomeFeedConstants.tabLoadMorePageSize,
                offset: offset,
                sizingMode: huntTodaySizingMode(),
                surface: tab.analyticsSurface
            )
            guard selectedFeedTab == tab else { return }
            guard case .success(let page) = result else { return }
            guard !page.isEmpty else {
                setTabHasMore(tab, false)
                return
            }
            let added = appendUniqueItems(page, to: tab)
            if added > 0 {
                syncItemsForSelectedTab()
                FeedListingImagePrefetch.prefetch(items: Array(page.prefix(8)))
            }
            setTabHasMore(
                tab,
                page.count >= HomeFeedConstants.tabLoadMorePageSize && added > 0
            )
            FeedPerformance.log("Home \(tab) loadMore @\(offset) -> +\(added) total=\(itemsForTab(tab).count)")
        }
    }

    private func setTabHasMore(_ tab: HomeFeedTab, _ hasMore: Bool) {
        if tab == .following {
            followingHasMore = hasMore
            return
        }
        var state = tabFeedState[tab.rawValue] ?? HomeTabFeedState()
        state.hasMore = hasMore
        tabFeedState[tab.rawValue] = state
    }

    private func setTabLoadingMore(_ tab: HomeFeedTab, _ loading: Bool) {
        if tab == .following {
            isLoadingMoreFollowing = loading
            return
        }
        var state = tabFeedState[tab.rawValue] ?? HomeTabFeedState()
        state.isLoadingMore = loading
        tabFeedState[tab.rawValue] = state
    }

    @discardableResult
    private func appendUniqueItems(_ page: [ListingFeedItem], to tab: HomeFeedTab) -> Int {
        var known = Set(itemsForTab(tab).map(\.id))
        let fresh = page.filter { known.insert($0.id).inserted }
        guard !fresh.isEmpty else { return 0 }
        switch tab {
        case .huntToday: sections.huntToday.append(contentsOf: fresh)
        case .forYou: sections.forYou.append(contentsOf: fresh)
        case .stylePicks: sections.stylePicks.append(contentsOf: fresh)
        case .similarSaved: sections.similarToSaved.append(contentsOf: fresh)
        case .seasonalNearYou: sections.seasonalNearYou.append(contentsOf: fresh)
        case .following: return 0
        }
        return fresh.count
    }

    private func loadFollowingTab(deps: AppDependencies, isGuestMode: Bool, force: Bool) async -> Bool {
        if isGuestMode { return true }
        if !force && loadedTabs.contains(HomeFeedTabKeys.following) && !followingWindow.items.isEmpty { return true }
        let result = await FeedPerformance.measure("Home following first page") {
            await fetchHomeFeedPageWithRetry(deps: deps, cursor: nil)
        }
        guard case .success(let page) = result else { return false }
        followingWindow.reset(with: page.items)
        followingItemIds = Set(page.items.map(\.id))
        followingNextCursor = page.nextCursor
        followingHasMore = page.hasMore
        if selectedFeedTab == .following { syncItemsForSelectedTab() }
        FeedPerformance.log("Home following items=\(followingWindow.items.count) hasMore=\(followingHasMore)")
        return true
    }

    private func fetchHomeFeedPageWithRetry(
        deps: AppDependencies,
        cursor: String?
    ) async -> Result<HomeFeedPage, Error> {
        func once() async -> Result<HomeFeedPage, Error> {
            await deps.listingRepository.getHomeFeedPage(
                limit: HomeFeedConstants.followPageSize,
                cursor: cursor
            )
        }
        var result = await once()
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(400))
            result = await once()
        }
        return result
    }

    /// Cursor API first; offset fallback when backend returns legacy bare array (`next_cursor` nil).
    private func fetchFollowingPage(
        deps: AppDependencies,
        cursor: String?,
        offsetFallback: Int?
    ) async -> Result<HomeFeedPage, Error> {
        if cursor != nil {
            return await fetchHomeFeedPageWithRetry(deps: deps, cursor: cursor)
        }
        if let offset = offsetFallback {
            func onceOffset() async -> Result<HomeFeedPage, Error> {
                switch await deps.listingRepository.getHomeFeed(
                    limit: HomeFeedConstants.followPageSize,
                    offset: offset
                ) {
                case .success(let items):
                    return .success(HomeFeedPage(
                        items: items,
                        hasMore: items.count >= HomeFeedConstants.followPageSize,
                        nextCursor: nil
                    ))
                case .failure(let error):
                    return .failure(error)
                }
            }
            var result = await onceOffset()
            if case .failure = result {
                try? await Task.sleep(for: .milliseconds(400))
                result = await onceOffset()
            }
            return result
        }
        return await fetchHomeFeedPageWithRetry(deps: deps, cursor: nil)
    }

    private func loadRecommendationSections(deps: AppDependencies, isGuestMode: Bool, force: Bool) async -> Bool {
        if !force && recommendationSectionsFetched { return true }
        if force {
            recommendationSectionsFetched = false
        }
        let styleLimit = sectionLimit(for: .stylePicks, fallback: 12)
        let similarLimit = sectionLimit(for: .similarSaved, fallback: 12)
        let result = await deps.recommendationRepository.homeSections(
            publicBrowse: isGuestMode,
            huntTodayLimit: sectionLimit(for: .huntToday, fallback: 12),
            forYouLimit: sectionLimit(for: .forYou, fallback: 16),
            sectionLimit: max(styleLimit, similarLimit),
            sizingMode: huntTodaySizingMode()
        )
        guard case .success(let loaded) = result else { return false }
        if !loaded.huntToday.isEmpty {
            sections.huntToday = loaded.huntToday
            loadedTabs.insert(HomeFeedTabKeys.huntToday)
        }
        sections.forYou = loaded.forYou
        sections.stylePicks = loaded.stylePicks
        sections.similarToSaved = loaded.similarToSaved
        sections.seasonalNearYou = loaded.seasonalNearYou
        sections.shoppingContext = loaded.shoppingContext ?? sections.shoppingContext
        recommendationSectionsFetched = true
        let forYouLimit = sectionLimit(for: .forYou, fallback: 16)
        let styleLimit = sectionLimit(for: .stylePicks, fallback: 12)
        let similarLimit = sectionLimit(for: .similarSaved, fallback: 12)
        let seasonalLimit = sectionLimit(for: .seasonalNearYou, fallback: 12)
        let huntLimit = sectionLimit(for: .huntToday, fallback: HomeFeedConstants.huntTodayLimit)
        if !loaded.huntToday.isEmpty {
            setTabHasMore(.huntToday, loaded.huntToday.count >= huntLimit)
        }
        setTabHasMore(.forYou, loaded.forYou.count >= forYouLimit)
        setTabHasMore(.stylePicks, loaded.stylePicks.count >= styleLimit)
        setTabHasMore(.similarSaved, loaded.similarToSaved.count >= similarLimit)
        setTabHasMore(.seasonalNearYou, loaded.seasonalNearYou.count >= seasonalLimit)
        syncItemsForSelectedTab()
        return true
    }

    func hasCachedItems(for tab: HomeFeedTab) -> Bool {
        !itemsForTab(tab).isEmpty
    }

    /// Immediate tab body swap from per-tab cache — avoids white flash while a tab reloads.
    func syncVisibleItemsForTab(_ tab: HomeFeedTab) {
        let cached = itemsForTab(tab)
        guard cached != items else { return }
        items = cached
    }

    private func syncItemsForSelectedTab() {
        let tab = selectedFeedTab
        let cached = itemsForTab(tab)
        if loadedTabs.contains(tab.rawValue), !tabsLoading.contains(tab.rawValue) {
            guard cached != items else {
                if !items.isEmpty { errorMessage = nil }
                return
            }
            items = cached
            if !items.isEmpty {
                errorMessage = nil
                FeedListingImagePrefetch.prefetch(items: items)
            }
            return
        }
        if !cached.isEmpty {
            guard cached != items else { return }
            items = cached
            return
        }
        if isRefreshing { return }
        if tabsLoading.contains(tab.rawValue) {
            if cached.isEmpty, !items.isEmpty {
                items = []
            } else if cached != items {
                items = cached
            }
        }
    }

    private func itemsForTab(_ tab: HomeFeedTab) -> [ListingFeedItem] {
        switch tab {
        case .forYou: return sections.forYou
        case .stylePicks: return sections.stylePicks
        case .similarSaved: return sections.similarToSaved
        case .seasonalNearYou: return sections.seasonalNearYou
        case .following: return followingWindow.items
        case .huntToday: return sections.huntToday
        }
    }

    var shoppingContextChip: String? {
        sections.shoppingContext?.chipLabel()
    }

    private func setTabLoading(_ tab: HomeFeedTab, _ loading: Bool) {
        if loading {
            tabsLoading.insert(tab.rawValue)
        } else {
            tabsLoading.remove(tab.rawValue)
        }
    }

    private func setTabError(_ tab: HomeFeedTab, _ error: Bool) {
        if error {
            tabsLoadError.insert(tab.rawValue)
        } else {
            tabsLoadError.remove(tab.rawValue)
        }
    }

    /// Realtime `feed.refresh` — Android HomeViewModel feed refresh hint.
    func handleFeedRefresh(deps: AppDependencies, isGuestMode: Bool) async {
        if !isGuestMode {
            await loadBuyerHomeStats(deps: deps, isGuestMode: false)
        }
        if selectedFeedTab == .following {
            loadedTabs.remove(HomeFeedTabKeys.following)
            ensureTabLoaded(.following, deps: deps, isGuestMode: isGuestMode, force: true)
        }
    }

    private func loadBuyerHomeStats(deps: AppDependencies, isGuestMode: Bool) async {
        guard !isGuestMode else {
            buyerStats = BuyerHomeStats()
            return
        }
        let previous = buyerStats
        async let ordersResult = deps.orderRepository.getBuyingOrders(limit: 50, offset: 0)
        async let summaryResult = deps.listingRepository.getMyListingsSummary()
        let orders = (try? await ordersResult.get()) ?? []
        let delivering = orders.filter { BuyerHomeStatsConstants.deliveringStatuses.contains($0.status.lowercased()) }.count

        var saved = previous.savedListingsCount
        var inReview = previous.listingsInReviewCount
        if case .success(let summary) = await summaryResult {
            saved = summary.wishlist
            inReview = summary.inReview
        } else {
            async let wishCount = deps.listingRepository.getWishlistSavedCount(limit: 1, offset: 0)
            async let inReviewList = deps.listingRepository.getMyListings(status: "in_review", limit: 50, offset: 0)
            if case .success(let count) = await wishCount { saved = count }
            if case .success(let list) = await inReviewList {
                inReview = list.filter { $0.isInReviewListing() }.count
            }
        }
        buyerStats = BuyerHomeStats(
            activeDeliveryOrders: delivering,
            savedListingsCount: saved,
            listingsInReviewCount: inReview
        )
    }

    private func refreshSizingBannerState(deps: AppDependencies, isGuestMode: Bool) async {
        guard !isGuestMode else {
            showSizingBanner = false
            return
        }
        if HomeSizingBannerPreference.isDismissed() {
            showSizingBanner = false
            return
        }
        guard deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            showSizingBanner = false
            return
        }
        guard case .success(let profile) = await deps.userRepository.getMeProfile() else {
            showSizingBanner = false
            return
        }
        let hasSize = !(profile.referenceSize?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let measurements = [
            profile.referenceMeasurementChest,
            profile.referenceMeasurementHem,
            profile.referenceMeasurementLength,
            profile.referenceMeasurementShoulders,
            profile.referenceMeasurementSleeveLength,
        ]
        let hasMeasurement = measurements.contains { ($0 ?? 0) > 0 }
        showSizingBanner = !hasSize && !hasMeasurement
    }

    func patchListingEngagement(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        patchListingInFeeds(id, transform: transform)
    }

    private func patchListingInFeeds(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        followingWindow.mapItems { $0.id == id ? transform($0) : $0 }
        sections.huntToday = sections.huntToday.map { $0.id == id ? transform($0) : $0 }
        sections.forYou = sections.forYou.map { $0.id == id ? transform($0) : $0 }
        sections.stylePicks = sections.stylePicks.map { $0.id == id ? transform($0) : $0 }
        sections.similarToSaved = sections.similarToSaved.map { $0.id == id ? transform($0) : $0 }
        sections.seasonalNearYou = sections.seasonalNearYou.map { $0.id == id ? transform($0) : $0 }
        if items.contains(where: { $0.id == id }) {
            items = items.map { $0.id == id ? transform($0) : $0 }
        } else {
            syncItemsForSelectedTab()
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
