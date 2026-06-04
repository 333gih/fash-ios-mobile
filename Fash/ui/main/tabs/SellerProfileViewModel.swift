import Foundation
import Observation

/// Android storefront: one batch per tab — no infinite scroll pagination.
private enum SellerStorefrontConstants {
    static let listingLimit = 50
    static let imagePrefetchCap = 12
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

    private var activeKey: String?
    private var activeSellerId: String?
    private var loadGeneration = 0
    private var loadedListingTabs = Set<Int>()
    private var tabLoadState: [Int: SellerTabLoadState] = [:]
    private let listingStallWatch = FeedLoadStallWatch()

    private struct SellerTabLoadState {
        var isLoadingFirstPage = false
        var isReloading = false
    }

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

    /// Storefront uses a single batch fetch (Android) — no scroll pagination.
    func hasMoreListings(for tab: SellerProfileTab) -> Bool {
        _ = tab
        return false
    }

    func isLoadingMoreListings(for tab: SellerProfileTab) -> Bool {
        _ = tab
        return false
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
        guard !isFirstPageLoading(for: tab), !isReloadingListings(for: tab) else { return }
        guard listings(for: tab).isEmpty else { return }
        guard !loadedListingTabs.contains(tab.rawValue) else { return }
        await loadListingsForTab(tab, deps: deps, isGuestMode: isGuestMode, force: false)
    }

    func isListingTabStalled(_ tab: SellerProfileTab) -> Bool {
        listingTabsStalled.contains(tab.rawValue)
    }

    func shouldShowListingGridSkeleton(for tab: SellerProfileTab) -> Bool {
        if isListingTabStalled(tab) { return false }
        if isFirstPageLoading(for: tab) || isReloadingListings(for: tab) { return true }
        if profile == nil { return isLoading }
        if !hasCompletedInitialLoad { return true }
        if listings(for: tab).isEmpty,
           !loadedListingTabs.contains(tab.rawValue),
           !isListingTabStalled(tab) {
            return true
        }
        return false
    }

    func retryListings(
        for tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async {
        listingTabsStalled.remove(tab.rawValue)
        listingStallWatch.cancel(key: String(tab.rawValue))
        loadedListingTabs.remove(tab.rawValue)
        await loadStorefrontListings(
            deps: deps,
            isGuestMode: isGuestMode,
            generation: loadGeneration,
            reloadAll: true,
            tabs: [tab]
        )
    }

    func requestLoadMore(for tab: SellerProfileTab, deps: AppDependencies, isGuestMode: Bool) {
        _ = (tab, deps, isGuestMode)
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

    /// Loads selling + sold in parallel (max [SellerStorefrontConstants.listingLimit] each) — matches Android.
    private func loadStorefrontListings(
        deps: AppDependencies,
        isGuestMode: Bool,
        generation: Int,
        reloadAll: Bool,
        tabs: [SellerProfileTab] = [.selling, .sold]
    ) async {
        guard generation == loadGeneration, let sellerId = resolvedSellerId() else { return }
        let toLoad = tabs.filter { reloadAll || !loadedListingTabs.contains($0.rawValue) }
        guard !toLoad.isEmpty else { return }

        for tab in toLoad {
            beginStorefrontTabLoad(tab)
        }

        if toLoad.contains(.selling), toLoad.contains(.sold) {
            async let sellingResult = fetchStorefrontListings(
                sellerId: sellerId, tab: .selling, deps: deps, isGuestMode: isGuestMode
            )
            async let soldResult = fetchStorefrontListings(
                sellerId: sellerId, tab: .sold, deps: deps, isGuestMode: isGuestMode
            )
            let (selling, sold) = await (sellingResult, soldResult)
            guard generation == loadGeneration else { return }
            finishStorefrontTabLoad(.selling, result: selling)
            finishStorefrontTabLoad(.sold, result: sold)
        } else if let tab = toLoad.first {
            let result = await fetchStorefrontListings(
                sellerId: sellerId, tab: tab, deps: deps, isGuestMode: isGuestMode
            )
            guard generation == loadGeneration else { return }
            finishStorefrontTabLoad(tab, result: result)
        }
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

    private func finishStorefrontTabLoad(_ tab: SellerProfileTab, result: Result<[ListingFeedItem], Error>) {
        mutateTabLoad(for: tab) { state in
            state.isLoadingFirstPage = false
            state.isReloading = false
        }
        listingStallWatch.cancel(key: String(tab.rawValue))
        listingTabsStalled.remove(tab.rawValue)

        switch result {
        case .success(let items):
            loadedListingTabs.insert(tab.rawValue)
            setListings(items, for: tab)
            prefetchStorefrontImages(items)
        case .failure:
            if listings(for: tab).isEmpty {
                loadedListingTabs.remove(tab.rawValue)
                setListings([], for: tab)
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
        await loadStorefrontListings(
            deps: deps,
            isGuestMode: isGuestMode,
            generation: loadGeneration,
            reloadAll: force,
            tabs: [tab]
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

    private func fetchStorefrontListings(
        sellerId: String,
        tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async -> Result<[ListingFeedItem], Error> {
        let status = tab == .sold ? "sold" : "active"
        let limit = SellerStorefrontConstants.listingLimit
        var result = await deps.listingRepository.getListingsBySeller(
            sellerId: sellerId,
            status: status,
            limit: limit,
            offset: 0,
            publicBrowse: isGuestMode
        )
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(350))
            result = await deps.listingRepository.getListingsBySeller(
                sellerId: sellerId,
                status: status,
                limit: limit,
                offset: 0,
                publicBrowse: isGuestMode
            )
        }
        switch result {
        case .success(let rawPage):
            return .success(normalizeStorefrontListings(rawPage, tab: tab))
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
        return Array(filtered.prefix(SellerStorefrontConstants.listingLimit))
    }

    private func setListings(_ items: [ListingFeedItem], for tab: SellerProfileTab) {
        switch tab {
        case .selling: sellingListings = items
        case .sold: soldListings = items
        }
    }

    private func patch(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        func map(_ items: [ListingFeedItem]) -> [ListingFeedItem] {
            items.map { cur in
                cur.id == id ? transform(cur) : cur
            }
        }
        sellingListings = map(sellingListings)
        soldListings = map(soldListings)
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
