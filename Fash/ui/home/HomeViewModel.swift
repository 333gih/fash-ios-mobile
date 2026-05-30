import Foundation
import Observation

private enum HomeFeedConstants {
    static let followPageSize = 20
    static let huntTodayLimit = 12
    static let staleThreshold: TimeInterval = 60
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
    var promoSlides: [AppAdvertisingSlideItem] = []
    var homeUxPersonalization = HomeUxPersonalization()
    var tabsLoading: Set<String> = []
    var tabsLoadError: Set<String> = []
    var followingHasMore = false
    var isLoadingMoreFollowing = false
    var buyerStats = BuyerHomeStats()
    var showSizingBanner = false
    private(set) var homeScrollToTopToken = 0

    private var sections = HomeRecommendationSections()
    private var followingItems: [ListingFeedItem] = []
    private var loadedTabs: Set<String> = []
    private var recommendationSectionsFetched = false
    private var tabLoadTasks: [String: Task<Void, Never>] = [:]
    private var homeUxApplied = false
    private var lastSuccessfulRefreshAt: Date?
    private var lastFollowFeedLoadMoreAt: Date?

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
        followingItems = []
        followingHasMore = false
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
        guard selectedFeedTab != tab else { return }
        deps.uxTabTracker.onTabOpened(scope: "home", tabKey: UxPersonalizationMapping.uxTabKey(for: tab))
        selectedFeedTabKey = tab.rawValue
        syncItemsForSelectedTab()
        ensureTabLoaded(tab, deps: deps, isGuestMode: isGuestMode)
        prefetchAdjacentTabs(around: tab, deps: deps, isGuestMode: isGuestMode)
    }

    /// Bottom-nav re-tap / pull-to-refresh — scroll feed to top (Android `requestScrollHomeToTop`).
    func requestScrollHomeToTop() {
        homeScrollToTopToken &+= 1
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

    func loadShell(deps: AppDependencies, isGuestMode: Bool, skipIfFresh: Bool = false, launchProgress: LaunchWaitingProgress? = nil) async {
        if skipIfFresh, isLaunchShellFresh {
            normalizeSelectedFeedTab(isGuestMode: isGuestMode, deps: deps)
            ensureTabLoaded(selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
            return
        }
        isShellLoading = true
        errorMessage = nil
        defer { isShellLoading = false }

        normalizeSelectedFeedTab(isGuestMode: isGuestMode, deps: deps)
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
            _ = await (ux, sections, stats, sizing)
        }

        async let sellersResult = deps.searchRepository.getFeaturedSellers(limit: 12, publicBrowse: isGuestMode)
        async let slidesResult = deps.advertisingRepository.getSlides(publicBrowse: isGuestMode)

        if case .success(let sellers) = await sellersResult {
            featuredSellers = sellers
        }
        launchProgress?.completeHomeStep()

        if case .success(let slides) = await slidesResult {
            promoSlides = slides.items
        }
        launchProgress?.completeHomeStep()

        ensureTabLoaded(selectedFeedTab, deps: deps, isGuestMode: isGuestMode, force: true)
        prefetchAdjacentTabs(around: selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
        launchProgress?.completeHomeStep()
        lastSuccessfulRefreshAt = Date()
    }

    func pullToRefresh(deps: AppDependencies, isGuestMode: Bool = false) async {
        requestScrollHomeToTop()
        isRefreshing = true
        defer {
            isRefreshing = false
            requestScrollHomeToTop()
        }
        invalidateAllTabFeeds()
        if !isGuestMode {
            async let ux: Void = loadUxPersonalization(deps: deps, isGuestMode: isGuestMode)
            async let sections: Bool = prefetchRecommendationSections(deps: deps, isGuestMode: isGuestMode)
            async let stats = loadBuyerHomeStats(deps: deps, isGuestMode: isGuestMode)
            async let sizing = refreshSizingBannerState(deps: deps, isGuestMode: isGuestMode)
            _ = await (ux, sections, stats, sizing)
        }
        async let sellersResult = deps.searchRepository.getFeaturedSellers(limit: 12, publicBrowse: isGuestMode)
        async let slidesResult = deps.advertisingRepository.getSlides(publicBrowse: isGuestMode)
        if case .success(let sellers) = await sellersResult {
            featuredSellers = sellers
        }
        if case .success(let slides) = await slidesResult {
            promoSlides = slides.items
        }
        ensureTabLoaded(selectedFeedTab, deps: deps, isGuestMode: isGuestMode, force: true)
        prefetchAdjacentTabs(around: selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
        lastSuccessfulRefreshAt = Date()
    }

    func retryTab(_ tab: HomeFeedTab, deps: AppDependencies, isGuestMode: Bool) {
        loadedTabs.remove(tab.rawValue)
        if HomeFeedTab.recommendationSectionTabs.contains(tab) {
            recommendationSectionsFetched = false
            HomeFeedTab.recommendationSectionTabs.forEach { loadedTabs.remove($0.rawValue) }
        }
        ensureTabLoaded(tab, deps: deps, isGuestMode: isGuestMode, force: true)
    }

    func loadMoreFollowing(deps: AppDependencies, isGuestMode: Bool) {
        guard !isGuestMode else { return }
        guard selectedFeedTab == .following else { return }
        guard !isLoadingMoreFollowing, followingHasMore else { return }
        guard !isShellLoading, !isRefreshing, !isTabLoading(.following) else { return }
        let offset = followingItems.count
        guard offset > 0 else { return }
        if let last = lastFollowFeedLoadMoreAt, Date().timeIntervalSince(last) < 0.9 { return }
        lastFollowFeedLoadMoreAt = Date()
        isLoadingMoreFollowing = true
        Task {
            defer { isLoadingMoreFollowing = false }
            let result = await deps.listingRepository.getHomeFeed(
                limit: HomeFeedConstants.followPageSize,
                offset: offset
            )
            guard case .success(let page) = result else { return }
            if page.isEmpty {
                followingHasMore = false
            } else {
                let existing = Set(followingItems.map(\.id))
                followingItems.append(contentsOf: page.filter { existing.contains($0.id) == false })
                followingHasMore = page.count >= HomeFeedConstants.followPageSize
                if selectedFeedTab == .following {
                    syncItemsForSelectedTab()
                }
            }
        }
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
        Task {
            switch await deps.listingRepository.toggleLike(listingId: item.id) {
            case .success(let liked):
                if liked {
                    deps.feedEventReporter.like(listingId: item.id, surface: surface, position: position)
                }
                deps.showSnackbar(FeedEngagementFeedback.likeMessage(liked: liked))
            case .failure(let error):
                deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
            }
        }
    }

    func toggleSave(_ item: ListingFeedItem, surface: String, position: Int, deps: AppDependencies, isGuestMode: Bool) {
        Task {
            switch await deps.listingRepository.toggleSave(
                listingId: item.id,
                currentlySaved: item.isSaved
            ) {
            case .success(let saved):
                patchListingInFeeds(item.id) { cur in
                    let delta = (saved && !cur.isSaved) ? 1 : ((!saved && cur.isSaved) ? -1 : 0)
                    return cur.withEngagement(
                        likeCount: cur.likeCount,
                        isLiked: cur.isLiked,
                        saveCount: max(0, cur.saveCount + delta),
                        isSaved: saved
                    )
                }
                if saved {
                    deps.feedEventReporter.save(listingId: item.id, surface: surface, position: position)
                }
                deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
                if !isGuestMode {
                    await loadBuyerHomeStats(deps: deps, isGuestMode: false)
                }
            case .failure(let error):
                deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
            }
        }
    }

    // MARK: - Private

    /// Shell was prefetched on the launch waiting screen — skip duplicate network on first Home appear.
    private var isLaunchShellFresh: Bool {
        guard let lastSuccessfulRefreshAt else { return false }
        guard Date().timeIntervalSince(lastSuccessfulRefreshAt) < 120 else { return false }
        return !items.isEmpty && (!promoSlides.isEmpty || !featuredSellers.isEmpty)
    }

    private func invalidateAllTabFeeds() {
        tabLoadTasks.values.forEach { $0.cancel() }
        tabLoadTasks.removeAll()
        loadedTabs.removeAll()
        recommendationSectionsFetched = false
        sections = HomeRecommendationSections()
        followingItems = []
        followingHasMore = false
        tabsLoading = []
        tabsLoadError = []
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
        if !force && loadedTabs.contains(tab.rawValue) { return }
        if tabsLoading.contains(tab.rawValue) { return }
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

        tabLoadTasks[tab.rawValue]?.cancel()
        tabLoadTasks[tab.rawValue] = Task {
            setTabLoading(tab, true)
            setTabError(tab, false)
            let ok = await loadTab(tab, deps: deps, isGuestMode: isGuestMode, force: force)
            if ok {
                loadedTabs.insert(tab.rawValue)
                if HomeFeedTab.recommendationSectionTabs.contains(tab) {
                    HomeFeedTab.recommendationSectionTabs.forEach { loadedTabs.insert($0.rawValue) }
                }
            } else {
                setTabError(tab, true)
            }
            setTabLoading(tab, false)
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
        case .forYou, .stylePicks, .similarSaved:
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
        homeUxPersonalization = bundle.home
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
        deps.uxTabTracker.onTabOpened(scope: "home", tabKey: UxPersonalizationMapping.uxTabKey(for: tab))
        syncItemsForSelectedTab()
        ensureTabLoaded(tab, deps: deps, isGuestMode: isGuestMode, force: !loadedTabs.contains(tab.rawValue))
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
        if selectedFeedTab == .huntToday { syncItemsForSelectedTab() }
        return true
    }

    private func loadFollowingTab(deps: AppDependencies, isGuestMode: Bool, force: Bool) async -> Bool {
        if isGuestMode { return true }
        if !force && loadedTabs.contains(HomeFeedTabKeys.following) && !followingItems.isEmpty { return true }
        let result = await fetchHomeFeedWithRetry(deps: deps)
        guard case .success(let feed) = result else { return false }
        followingItems = feed
        followingHasMore = feed.count >= HomeFeedConstants.followPageSize
        if selectedFeedTab == .following { syncItemsForSelectedTab() }
        return true
    }

    private func loadRecommendationSections(deps: AppDependencies, isGuestMode: Bool, force: Bool) async -> Bool {
        if !force && recommendationSectionsFetched { return true }
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
        recommendationSectionsFetched = true
        syncItemsForSelectedTab()
        return true
    }

    private func fetchHomeFeedWithRetry(deps: AppDependencies) async -> Result<[ListingFeedItem], Error> {
        func once() async -> Result<[ListingFeedItem], Error> {
            await deps.listingRepository.getHomeFeed(limit: HomeFeedConstants.followPageSize, offset: 0)
        }
        var result = await once()
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(400))
            result = await once()
        }
        if case .success(let page) = result {
            followingHasMore = page.count >= HomeFeedConstants.followPageSize
        }
        return result
    }

    private func syncItemsForSelectedTab() {
        items = itemsForTab(selectedFeedTab)
        if !items.isEmpty {
            errorMessage = nil
            FeedListingImagePrefetch.prefetch(items: items)
        }
    }

    private func itemsForTab(_ tab: HomeFeedTab) -> [ListingFeedItem] {
        switch tab {
        case .forYou: return sections.forYou
        case .stylePicks: return sections.stylePicks
        case .similarSaved: return sections.similarToSaved
        case .following: return followingItems
        case .huntToday: return sections.huntToday
        }
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
        async let ordersResult = deps.orderRepository.getBuyingOrders(limit: 50, offset: 0)
        async let savedResult = deps.listingRepository.getWishlistSavedCount(limit: 100, offset: 0)
        async let mineResult = deps.listingRepository.getMyListings(limit: 50, offset: 0)
        let orders = (try? await ordersResult.get()) ?? []
        let saved = (try? await savedResult.get()) ?? 0
        let inReview = ((try? await mineResult.get()) ?? []).filter { $0.isInReviewListing() }.count
        let delivering = orders.filter { BuyerHomeStatsConstants.deliveringStatuses.contains($0.status.lowercased()) }.count
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

    private func patchListingInFeeds(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        followingItems = followingItems.map { $0.id == id ? transform($0) : $0 }
        sections.huntToday = sections.huntToday.map { $0.id == id ? transform($0) : $0 }
        sections.forYou = sections.forYou.map { $0.id == id ? transform($0) : $0 }
        sections.stylePicks = sections.stylePicks.map { $0.id == id ? transform($0) : $0 }
        sections.similarToSaved = sections.similarToSaved.map { $0.id == id ? transform($0) : $0 }
        syncItemsForSelectedTab()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
