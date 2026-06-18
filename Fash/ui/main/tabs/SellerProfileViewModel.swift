import Foundation
import Observation

/// Paginated storefront listings — page size aligned with own [ProfileViewModel].
private enum SellerStorefrontConstants {
    static let listingPageSize = 20
    static let imagePrefetchCap = 8
    static let slidingWindowPolicy = FeedSlidingWindowPolicy.sellerStorefront
}

@Observable
@MainActor
final class SellerProfileViewModel {
    var profile: ProfileInfo?
    var aestheticCatalog: [CommonAestheticTagDto] = []
    var sellerFocus: SellerListingFocus?
    var sellerFocusForbidden = false
    var sellerFocusLoading = false
    var sellingListings: [ListingFeedItem] = []
    var soldListings: [ListingFeedItem] = []
    var isLoading = false
    var isRefreshing = false
    var loadError = false
    var hasCompletedInitialLoad = false
    var listingTabsStalled: Set<Int> = []
    var isFollowing = false
    var followInFlight = false
    var selectedTab = SellerProfileTab.selling.rawValue
    var listingScrollTrimToken = 0
    private(set) var listingScrollTrimSignedDeltaY: CGFloat = 0

    private var activeKey: String?
    private var activeSellerId: String?
    private var loadGeneration = 0
    private var loadedListingTabs = Set<Int>()
    private var tabLoadState: [Int: SellerTabLoadState] = [:]
    private var tabPagination: [Int: SellerTabPagination] = [:]
    private var loadMoreTasks: [Int: Task<Void, Never>] = [:]
    private var backfillTasks: [Int: Task<Void, Never>] = [:]
    private var trimTasks: [Int: Task<Void, Never>] = [:]
    private var listingWindows: [Int: SellerListingWindowState] = [:]
    private let listingStallWatch = FeedLoadStallWatch()

    private struct SellerListingWindowState {
        var window = FeedSlidingWindow()
        var knownIds = Set<String>()
        var isBackfilling = false
    }

    private struct SellerTabLoadState {
        var isLoadingFirstPage = false
        var isReloading = false
    }

    private struct SellerTabPagination {
        var hasMore = true
        var nextOffset = 0
        var isLoadingMore = false
        var fetchGeneration = 0
        var loadMoreCooldownUntil: Date?
    }

    private struct ListingPagePayload {
        let items: [ListingFeedItem]
        let rawCount: Int
    }

    private func nextListingOffset(afterFetchingAt offset: Int, rawCount: Int) -> Int {
        let pageSize = SellerStorefrontConstants.listingPageSize
        let pageIndex = max(0, offset / pageSize)
        if rawCount < pageSize {
            return offset + rawCount
        }
        return (pageIndex + 1) * pageSize
    }

    /// Scroll boundary from [HomeFeedScrollCoordinator] — gates trim/backfill while finger is on screen.
    @ObservationIgnored
    var scrollBoundary: HomeFeedScrollBoundary?

    func loadForSeller(_ username: String, deps: AppDependencies, isGuestMode: Bool, force: Bool = false) async {
        let key = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !key.isEmpty else { return }
        if !force, key == activeKey, profile != nil { return }

        loadGeneration += 1
        let generation = loadGeneration

        let sellerChanged = activeKey != nil && activeKey != key
        activeKey = key
        if sellerChanged || profile == nil {
            profile = nil
            sellingListings = []
            soldListings = []
            sellerFocus = nil
            isFollowing = false
            selectedTab = SellerProfileTab.selling.rawValue
            hasCompletedInitialLoad = false
            activeSellerId = nil
            loadedListingTabs = []
            listingTabsStalled = []
            listingStallWatch.cancelAll()
            tabLoadState = [:]
            tabPagination = [:]
            loadMoreTasks.values.forEach { $0.cancel() }
            loadMoreTasks = [:]
            backfillTasks.values.forEach { $0.cancel() }
            backfillTasks = [:]
            trimTasks.values.forEach { $0.cancel() }
            trimTasks = [:]
            listingWindows = [:]
        }
        let showBlocking = profile == nil
        if showBlocking {
            isLoading = true
        } else if sellerChanged {
            isRefreshing = true
        } else {
            isRefreshing = force
        }
        defer {
            if generation == loadGeneration {
                isLoading = false
                isRefreshing = false
            }
        }
        loadError = false

        if force, profile != nil {
            sellingListings = []
            soldListings = []
            loadedListingTabs = []
            tabPagination = [:]
            loadMoreTasks.values.forEach { $0.cancel() }
            loadMoreTasks = [:]
            backfillTasks.values.forEach { $0.cancel() }
            backfillTasks = [:]
            trimTasks.values.forEach { $0.cancel() }
            trimTasks = [:]
            listingWindows = [:]
        }

        async let tagsResult = deps.commonCatalogRepository.getAestheticTags(all: true)
        let profileResult = await fetchSellerProfileWithRetry(
            key: key,
            deps: deps,
            isGuestMode: isGuestMode
        )
        guard generation == loadGeneration else { return }

        switch profileResult {
        case .success(let prof):
            profile = prof
            loadError = false
            isFollowing = isGuestMode ? false : prof.isFollowing
            if case .success(let tags) = await tagsResult {
                guard generation == loadGeneration else { return }
                aestheticCatalog = tags
            }
            activeSellerId = prof.userId.trimmingCharacters(in: .whitespaces).isEmpty ? key : prof.userId
            async let focusTask: Void = loadSellerFocus(
                username: key,
                deps: deps,
                isGuestMode: isGuestMode,
                generation: generation
            )
            await loadStorefrontListings(
                deps: deps,
                isGuestMode: isGuestMode,
                generation: generation,
                reloadAll: showBlocking || force
            )
            guard generation == loadGeneration else { return }
            hasCompletedInitialLoad = true
            await focusTask
            guard generation == loadGeneration else { return }
        case .failure:
            guard generation == loadGeneration else { return }
            loadError = true
            hasCompletedInitialLoad = true
        }
    }

    private func fetchSellerProfileWithRetry(
        key: String,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async -> Result<ProfileInfo, Error> {
        func profileFetchAttempt() async -> Result<ProfileInfo, Error> {
            if isGuestMode {
                await deps.userRepository.getProfilePublic(key)
            } else {
                await deps.userRepository.getProfile(key)
            }
        }
        var result = await profileFetchAttempt()
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(400))
            result = await profileFetchAttempt()
        }
        return result
    }

    private func loadSellerFocus(
        username: String,
        deps: AppDependencies,
        isGuestMode: Bool,
        generation: Int
    ) async {
        guard generation == loadGeneration else { return }
        guard !isGuestMode else {
            sellerFocus = nil
            sellerFocusForbidden = false
            return
        }
        sellerFocusLoading = true
        sellerFocusForbidden = false
        defer { sellerFocusLoading = false }
        switch await deps.userRepository.getSellerListingFocus(username) {
        case .success(let focus):
            guard generation == loadGeneration else { return }
            sellerFocus = focus.isEmpty ? nil : focus
        case .failure(let err):
            guard generation == loadGeneration else { return }
            if err as? SellerFocusError == .forbidden {
                sellerFocusForbidden = true
            }
            sellerFocus = nil
        }
    }

    func toggleFollow(deps: AppDependencies, isGuestMode: Bool) async {
        guard !isGuestMode, let prof = profile, canFollow(deps: deps) else { return }
        let target = prof.userId.nilIfEmpty ?? prof.username.nilIfEmpty
        guard let target, !target.isEmpty else { return }
        followInFlight = true
        defer { followInFlight = false }
        let wasFollowing = isFollowing
        let result: Result<Void, Error> = if wasFollowing {
            await deps.userRepository.unfollow(target)
        } else {
            await deps.userRepository.follow(target)
        }
        switch result {
        case .success:
            isFollowing = !wasFollowing
            profile = copyProfile(prof, isFollowing: isFollowing, followerDelta: isFollowing ? 1 : -1)
            if isFollowing {
                deps.showSnackbar(L10n.followSuccess)
            }
        case .failure(let error):
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        }
    }

    func toggleLike(_ item: ListingFeedItem, deps: AppDependencies) async {
        let snapshot = item
        guard deps.listingEngagement.beginLikeToggle(listingId: item.id) else { return }
        patch(item.id) { _ in snapshot.toggledLike }
        defer { deps.listingEngagement.endLikeToggle(listingId: item.id) }
        switch await deps.listingRepository.toggleLike(listingId: item.id) {
        case .success(let liked):
            patch(item.id) { _ in snapshot.applyingLikeToggle(liked) }
            if liked {
                deps.feedEventReporter.like(listingId: item.id, surface: "seller_profile")
            }
            deps.showSnackbar(FeedEngagementFeedback.likeMessage(liked: liked))
        case .failure(let error):
            patch(item.id) { _ in snapshot }
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        }
    }

    func toggleSave(_ item: ListingFeedItem, deps: AppDependencies) async {
        let snapshot = item
        guard deps.listingEngagement.beginSaveToggle(listingId: item.id) else { return }
        patch(item.id) { _ in snapshot.toggledSave }
        defer { deps.listingEngagement.endSaveToggle(listingId: item.id) }
        switch await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: snapshot.isSaved) {
        case .success(let saved):
            patch(item.id) { _ in snapshot.applyingSaveToggle(saved) }
            if saved {
                deps.feedEventReporter.save(listingId: item.id, surface: "seller_profile")
            }
            deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
        case .failure(let error):
            patch(item.id) { _ in snapshot }
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        }
    }

    func canFollow(deps: AppDependencies) -> Bool {
        guard let prof = profile,
              let myId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespaces),
              !myId.isEmpty else { return false }
        return myId.caseInsensitiveCompare(prof.userId) != .orderedSame
    }

    func canShowFollowUi(deps: AppDependencies, isGuestMode: Bool) -> Bool {
        guard let prof = profile, !prof.userId.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if isGuestMode { return true }
        return canFollow(deps: deps)
    }

    var listingsForSelectedTab: [ListingFeedItem] {
        listings(for: SellerProfileTab(rawValue: selectedTab) ?? .selling)
    }

    func listings(for tab: SellerProfileTab) -> [ListingFeedItem] {
        switch tab {
        case .sold: return soldListings
        case .selling: return sellingListings
        }
    }

    /// True when another page is available for scroll pagination.
    func hasMoreListings(for tab: SellerProfileTab) -> Bool {
        pagination(for: tab).hasMore
    }

    func isLoadingMoreListings(for tab: SellerProfileTab) -> Bool {
        pagination(for: tab).isLoadingMore
    }

    func isReloadingListings(for tab: SellerProfileTab) -> Bool {
        tabLoad(for: tab).isReloading
    }

    func isFirstPageLoading(for tab: SellerProfileTab) -> Bool {
        let state = tabLoad(for: tab)
        return listings(for: tab).isEmpty && (state.isLoadingFirstPage || state.isReloading)
    }

    func onTabSelected(_ tabIndex: Int, deps: AppDependencies, isGuestMode: Bool) {
        guard let tab = SellerProfileTab(rawValue: tabIndex) else { return }
        Task { await ensureListingsLoaded(for: tab, deps: deps, isGuestMode: isGuestMode) }
    }

    func ensureListingsLoaded(
        for tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async {
        guard profile != nil else { return }
        guard listings(for: tab).isEmpty else { return }
        guard !loadedListingTabs.contains(tab.rawValue) else { return }
        await loadListingsForTab(tab, deps: deps, isGuestMode: isGuestMode, force: false)
    }

    func isListingTabStalled(_ tab: SellerProfileTab) -> Bool {
        listingTabsStalled.contains(tab.rawValue)
    }

    var isShellLoading: Bool {
        isLoading && profile == nil && !loadError
    }

    func shouldShowListingGridSkeleton(for tab: SellerProfileTab) -> Bool {
        if isListingTabStalled(tab) { return false }
        if isShellLoading { return true }
        if isTabListingsPending(for: tab) { return true }
        return listings(for: tab).isEmpty && isFirstPageLoading(for: tab)
    }

    /// Empty tab whose first page has not landed yet — show grid skeleton (e.g. Đã bán on first open).
    func isTabListingsPending(for tab: SellerProfileTab) -> Bool {
        guard profile != nil else { return false }
        guard listings(for: tab).isEmpty else { return false }
        return !loadedListingTabs.contains(tab.rawValue)
    }

    func retryListings(
        for tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async {
        listingTabsStalled.remove(tab.rawValue)
        listingStallWatch.cancel(key: String(tab.rawValue))
        loadedListingTabs.remove(tab.rawValue)
        listingWindows[tab.rawValue] = nil
        mutatePagination(for: tab) { $0 = SellerTabPagination() }
        await fetchListingsFirstPage(
            tab,
            deps: deps,
            isGuestMode: isGuestMode,
            generation: loadGeneration,
            force: true
        )
    }

    func requestLoadMore(for tab: SellerProfileTab, deps: AppDependencies, isGuestMode: Bool) {
        guard canLoadMore(for: tab) else { return }
        guard loadMoreTasks[tab.rawValue] == nil else { return }
        loadMoreTasks[tab.rawValue] = Task { @MainActor in
            defer { loadMoreTasks[tab.rawValue] = nil }
            await loadMoreListings(for: tab, deps: deps, isGuestMode: isGuestMode)
        }
    }

    /// TikTok-style window — trim/backfill only after scroll idle (never while dragging).
    func notifyListingCellVisible(
        tab: SellerProfileTab,
        visibleIndex: Int,
        columnWidth: CGFloat,
        deps: AppDependencies,
        isGuestMode: Bool
    ) {
        guard columnWidth > 1 else { return }
        scheduleDeferredWindowMaintenance(
            tab: tab,
            visibleIndex: visibleIndex,
            columnWidth: columnWidth,
            deps: deps,
            isGuestMode: isGuestMode
        )
    }

    private func scheduleDeferredWindowMaintenance(
        tab: SellerProfileTab,
        visibleIndex: Int,
        columnWidth: CGFloat,
        deps: AppDependencies,
        isGuestMode: Bool
    ) {
        trimTasks[tab.rawValue]?.cancel()
        trimTasks[tab.rawValue] = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(240))
            guard !Task.isCancelled else { return }
            guard SellerProfileTab(rawValue: selectedTab) == tab else { return }
            guard !(scrollBoundary?.isUserInteracting ?? false) else { return }
            guard !isLoadingMoreListings(for: tab) else { return }

            var state = listingWindowState(for: tab)
            if let trim = state.window.trimFrontIfNeeded(
                visibleIndex: visibleIndex,
                columnWidth: columnWidth,
                policy: SellerStorefrontConstants.slidingWindowPolicy
            ) {
                listingWindows[tab.rawValue] = state
                syncListingsFromWindow(tab)
                applyScrollCompensation(-trim.scrollDeltaY)
                FeedPerformance.log(
                    "Seller \(tab) trim -\(trim.removedCount) window=\(state.window.items.count)"
                )
            }

            requestBackfillIfNeeded(
                tab: tab,
                visibleIndex: visibleIndex,
                columnWidth: columnWidth,
                deps: deps,
                isGuestMode: isGuestMode
            )
        }
    }

    func patchListingEngagement(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        patch(id, transform: transform)
    }

    private func tabLoad(for tab: SellerProfileTab) -> SellerTabLoadState {
        tabLoadState[tab.rawValue] ?? SellerTabLoadState()
    }

    private func mutateTabLoad(for tab: SellerProfileTab, _ transform: (inout SellerTabLoadState) -> Void) {
        var state = tabLoad(for: tab)
        transform(&state)
        tabLoadState[tab.rawValue] = state
    }

    private func resolvedSellerId() -> String? {
        guard let id = activeSellerId?.trimmingCharacters(in: .whitespaces), !id.isEmpty else { return nil }
        return id
    }

    /// Loads selling + sold first pages in parallel on profile open; single-tab on tab switch.
    private func loadStorefrontListings(
        deps: AppDependencies,
        isGuestMode: Bool,
        generation: Int,
        reloadAll: Bool,
        tabs: [SellerProfileTab] = [.selling, .sold]
    ) async {
        guard generation == loadGeneration, resolvedSellerId() != nil else { return }
        let toLoad = tabs.filter { reloadAll || !loadedListingTabs.contains($0.rawValue) }
        guard !toLoad.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for tab in toLoad {
                group.addTask { @MainActor in
                    await self.fetchListingsFirstPage(
                        tab,
                        deps: deps,
                        isGuestMode: isGuestMode,
                        generation: generation,
                        force: reloadAll
                    )
                }
            }
        }
    }

    private func fetchListingsFirstPage(
        _ tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool,
        generation: Int,
        force: Bool
    ) async {
        guard generation == loadGeneration, resolvedSellerId() != nil else { return }
        if force {
            mutatePagination(for: tab) { state in
                state.fetchGeneration += 1
                state.hasMore = true
                state.nextOffset = 0
            }
        } else if loadedListingTabs.contains(tab.rawValue) {
            return
        } else {
            let p = pagination(for: tab)
            if p.isLoadingMore || tabLoad(for: tab).isLoadingFirstPage || tabLoad(for: tab).isReloading {
                return
            }
        }

        let pageGeneration = pagination(for: tab).fetchGeneration
        beginStorefrontTabLoad(tab)

        let result = await fetchStorefrontPage(
            tab: tab,
            offset: 0,
            deps: deps,
            isGuestMode: isGuestMode
        )
        guard generation == loadGeneration, pageGeneration == pagination(for: tab).fetchGeneration else { return }
        finishStorefrontFirstPage(tab, result: result)
    }

    private func loadMoreListings(
        for tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async {
        guard canLoadMore(for: tab) else { return }
        let now = Date()
        if let until = pagination(for: tab).loadMoreCooldownUntil, now < until { return }
        mutatePagination(for: tab) { $0.loadMoreCooldownUntil = now.addingTimeInterval(0.4) }

        let generation = pagination(for: tab).fetchGeneration
        let offset = pagination(for: tab).nextOffset
        guard offset > 0 else { return }

        mutatePagination(for: tab) { $0.isLoadingMore = true }
        defer { mutatePagination(for: tab) { $0.isLoadingMore = false } }

        let result = await fetchStorefrontPage(
            tab: tab,
            offset: offset,
            deps: deps,
            isGuestMode: isGuestMode
        )
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
                prefetchStorefrontImages(Array(state.window.items.suffix(added)))
            }
            mutatePagination(for: tab) { state in
                state.nextOffset = nextListingOffset(afterFetchingAt: offset, rawCount: page.rawCount)
                if page.rawCount < SellerStorefrontConstants.listingPageSize {
                    state.hasMore = false
                } else if added == 0 {
                    state.hasMore = false
                } else {
                    state.hasMore = true
                }
            }
            FeedPerformance.log(
                "Seller \(tab) loadMore @\(offset) -> +\(added) window=\(listings(for: tab).count) logical=\(state.window.logicalStartIndex)"
            )
        case .failure:
            FeedPerformance.log("Seller \(tab) loadMore @\(offset) failed")
        }
    }

    private func canLoadMore(for tab: SellerProfileTab) -> Bool {
        let p = pagination(for: tab)
        return p.hasMore
            && p.nextOffset > 0
            && !p.isLoadingMore
            && !tabLoad(for: tab).isLoadingFirstPage
            && !tabLoad(for: tab).isReloading
            && !isRefreshing
            && !listings(for: tab).isEmpty
    }

    private func pagination(for tab: SellerProfileTab) -> SellerTabPagination {
        tabPagination[tab.rawValue] ?? SellerTabPagination()
    }

    private func mutatePagination(for tab: SellerProfileTab, _ transform: (inout SellerTabPagination) -> Void) {
        var state = pagination(for: tab)
        transform(&state)
        tabPagination[tab.rawValue] = state
    }

    private func beginStorefrontTabLoad(_ tab: SellerProfileTab) {
        listingTabsStalled.remove(tab.rawValue)
        let hadItems = !listings(for: tab).isEmpty
        mutateTabLoad(for: tab) { state in
            state.isLoadingFirstPage = !hadItems
            state.isReloading = hadItems
        }
        scheduleListingStallWatch(for: tab)
    }

    private func finishStorefrontFirstPage(_ tab: SellerProfileTab, result: Result<ListingPagePayload, Error>) {
        mutateTabLoad(for: tab) { state in
            state.isLoadingFirstPage = false
            state.isReloading = false
        }
        listingStallWatch.cancel(key: String(tab.rawValue))
        listingTabsStalled.remove(tab.rawValue)

        switch result {
        case .success(let page):
            loadedListingTabs.insert(tab.rawValue)
            setListings(page.items, for: tab)
            mutatePagination(for: tab) { state in
                state.nextOffset = nextListingOffset(afterFetchingAt: 0, rawCount: page.rawCount)
                state.hasMore = page.rawCount >= SellerStorefrontConstants.listingPageSize
            }
            prefetchStorefrontImages(page.items)
            FeedPerformance.log(
                "Seller \(tab) first page -> items=\(page.items.count) hasMore=\(page.rawCount >= SellerStorefrontConstants.listingPageSize)"
            )
        case .failure:
            if listings(for: tab).isEmpty {
                loadedListingTabs.remove(tab.rawValue)
                setListings([], for: tab)
                mutatePagination(for: tab) { $0.hasMore = false }
            }
        }
    }

    private func loadListingsForTab(
        _ tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool,
        force: Bool
    ) async {
        if !force, loadedListingTabs.contains(tab.rawValue) { return }
        await fetchListingsFirstPage(
            tab,
            deps: deps,
            isGuestMode: isGuestMode,
            generation: loadGeneration,
            force: force
        )
    }

    private func prefetchStorefrontImages(_ items: [ListingFeedItem]) {
        let cap = min(items.count, SellerStorefrontConstants.imagePrefetchCap)
        guard cap > 0 else { return }
        FeedListingImagePrefetch.prefetch(items: Array(items.prefix(cap)))
    }

    private func scheduleListingStallWatch(for tab: SellerProfileTab) {
        let key = String(tab.rawValue)
        listingStallWatch.schedule(key: key) { [weak self] in
            guard let self else { return false }
            guard self.profile != nil else { return false }
            guard self.selectedTab == tab.rawValue else { return false }
            guard !self.loadedListingTabs.contains(tab.rawValue) else { return false }
            guard !self.isFirstPageLoading(for: tab) else { return false }
            guard self.listings(for: tab).isEmpty else { return false }
            return true
        } onStalled: { [weak self] in
            self?.listingTabsStalled.insert(tab.rawValue)
        }
    }

    private func fetchStorefrontPage(
        tab: SellerProfileTab,
        offset: Int,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async -> Result<ListingPagePayload, Error> {
        guard let sellerId = resolvedSellerId() else {
            return .failure(URLError(.badURL))
        }
        let status = tab == .sold ? "sold" : "active"
        let limit = SellerStorefrontConstants.listingPageSize
        var result = await deps.listingRepository.getListingsBySeller(
            sellerId: sellerId,
            status: status,
            limit: limit,
            offset: offset,
            publicBrowse: isGuestMode
        )
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(350))
            result = await deps.listingRepository.getListingsBySeller(
                sellerId: sellerId,
                status: status,
                limit: limit,
                offset: offset,
                publicBrowse: isGuestMode
            )
        }
        switch result {
        case .success(let rawPage):
            let normalized = normalizeStorefrontListings(rawPage, tab: tab)
            let items = Array(normalized.prefix(limit))
            let delivered = min(rawPage.count, limit)
            return .success(ListingPagePayload(items: items, rawCount: delivered))
        case .failure(let error):
            return .failure(error)
        }
    }

    private func normalizeStorefrontListings(
        _ rawPage: [ListingFeedItem],
        tab: SellerProfileTab
    ) -> [ListingFeedItem] {
        let filtered: [ListingFeedItem]
        if tab == .selling {
            filtered = rawPage.filter { ($0.listingStatus ?? "").lowercased() != "sold" }
        } else {
            filtered = rawPage
        }
        return Array(filtered.prefix(SellerStorefrontConstants.listingPageSize))
    }

    private func listingWindowState(for tab: SellerProfileTab) -> SellerListingWindowState {
        listingWindows[tab.rawValue] ?? SellerListingWindowState()
    }

    private func syncListingsFromWindow(_ tab: SellerProfileTab) {
        let items = listingWindows[tab.rawValue]?.window.items ?? []
        switch tab {
        case .selling: sellingListings = items
        case .sold: soldListings = items
        }
    }

    private func applyScrollCompensation(_ signedDeltaY: CGFloat) {
        guard abs(signedDeltaY) > 0.5 else { return }
        listingScrollTrimSignedDeltaY = signedDeltaY
        listingScrollTrimToken += 1
    }

    private func requestBackfillIfNeeded(
        tab: SellerProfileTab,
        visibleIndex: Int,
        columnWidth: CGFloat,
        deps: AppDependencies,
        isGuestMode: Bool
    ) {
        let policy = SellerStorefrontConstants.slidingWindowPolicy
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
            let offset = max(0, logicalStart - SellerStorefrontConstants.listingPageSize)
            let result = await self.fetchStorefrontPage(
                tab: tab,
                offset: offset,
                deps: deps,
                isGuestMode: isGuestMode
            )
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
            self.prefetchStorefrontImages(Array(page.items.prefix(SellerStorefrontConstants.imagePrefetchCap)))
            FeedPerformance.log(
                "Seller \(tab) backfill @\(offset) +\(prepend.addedCount) window=\(s.window.items.count) logical=\(s.window.logicalStartIndex)"
            )
        }
    }

    private func appendListings(_ items: [ListingFeedItem], for tab: SellerProfileTab) {
        var state = listingWindowState(for: tab)
        _ = state.window.appendUnique(items, knownIds: &state.knownIds)
        listingWindows[tab.rawValue] = state
        syncListingsFromWindow(tab)
    }

    private func setListings(_ items: [ListingFeedItem], for tab: SellerProfileTab) {
        var state = SellerListingWindowState()
        state.knownIds = Set(items.map(\.id))
        state.window.reset(with: items)
        listingWindows[tab.rawValue] = state
        syncListingsFromWindow(tab)
    }

    private func patch(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        for tab in [SellerProfileTab.selling, .sold] {
            guard var state = listingWindows[tab.rawValue] else { continue }
            state.window.mapItems { $0.id == id ? transform($0) : $0 }
            listingWindows[tab.rawValue] = state
            syncListingsFromWindow(tab)
        }
    }

    private func copyProfile(_ prof: ProfileInfo, isFollowing: Bool, followerDelta: Int) -> ProfileInfo {
        ProfileInfo(
            userId: prof.userId,
            username: prof.username,
            displayName: prof.displayName,
            avatarUrl: prof.avatarUrl,
            coverImageUrl: prof.coverImageUrl,
            followerCount: max(0, prof.followerCount + followerDelta),
            followingCount: prof.followingCount,
            productCount: prof.productCount,
            bio: prof.bio,
            isFollowing: isFollowing,
            aestheticTags: prof.aestheticTags,
            aestheticTagSnapshots: prof.aestheticTagSnapshots,
            referenceSize: prof.referenceSize,
            referenceMeasurementUnit: prof.referenceMeasurementUnit,
            referenceMeasurementChest: prof.referenceMeasurementChest,
            referenceMeasurementHem: prof.referenceMeasurementHem,
            referenceMeasurementLength: prof.referenceMeasurementLength,
            referenceMeasurementShoulders: prof.referenceMeasurementShoulders,
            referenceMeasurementSleeveLength: prof.referenceMeasurementSleeveLength,
            gender: prof.gender,
            soldCount: prof.soldCount,
            rating: prof.rating,
            reviewCount: prof.reviewCount,
            verified: prof.verified,
            hasFastDelivery: prof.hasFastDelivery,
            reputationPoints: prof.reputationPoints,
            meetingNoShowWarning: prof.meetingNoShowWarning,
            sizingReferenceCompleted: prof.sizingReferenceCompleted,
            heightCm: prof.heightCm,
            weightKg: prof.weightKg,
            accountEmail: prof.accountEmail,
            accountPhone: prof.accountPhone,
            topBadges: prof.topBadges
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
