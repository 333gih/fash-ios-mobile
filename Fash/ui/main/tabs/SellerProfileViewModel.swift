import Foundation
import Observation

private let sellerListingPageSize = 20

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
    var isFollowing = false
    var followInFlight = false
    var selectedTab = SellerProfileTab.selling.rawValue

    private var activeKey: String?
    private var activeSellerId: String?
    private var loadGeneration = 0
    private var loadedListingTabs = Set<Int>()
    private var tabPagination: [Int: SellerTabPagination] = [:]
    private var loadMoreTasks: [Int: Task<Void, Never>] = [:]

    private struct SellerTabPagination {
        var hasMore = true
        var nextOffset = 0
        var isLoadingMore = false
        var isLoadingFirstPage = false
        var isReloading = false
        var fetchGeneration = 0
        var loadMoreCooldownUntil: Date?
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
            tabPagination = [:]
            loadMoreTasks.values.forEach { $0.cancel() }
            loadMoreTasks = [:]
        }
        let showBlocking = profile == nil
        if showBlocking { isLoading = true } else { isRefreshing = true }
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
            hasCompletedInitialLoad = true
            let initialTab = SellerProfileTab(rawValue: selectedTab) ?? .selling
            async let focusTask: Void = loadSellerFocus(
                username: key,
                deps: deps,
                isGuestMode: isGuestMode,
                generation: generation
            )
            if showBlocking {
                await fetchListingsFirstPage(
                    initialTab,
                    deps: deps,
                    isGuestMode: isGuestMode,
                    generation: generation,
                    force: true
                )
            } else {
                await reloadListingFeedOnRefresh(
                    activeTab: initialTab,
                    deps: deps,
                    isGuestMode: isGuestMode,
                    generation: generation
                )
            }
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

    func hasMoreListings(for tab: SellerProfileTab) -> Bool {
        pagination(for: tab).hasMore
    }

    func isLoadingMoreListings(for tab: SellerProfileTab) -> Bool {
        pagination(for: tab).isLoadingMore
    }

    func isReloadingListings(for tab: SellerProfileTab) -> Bool {
        pagination(for: tab).isReloading
    }

    func isFirstPageLoading(for tab: SellerProfileTab) -> Bool {
        let p = pagination(for: tab)
        return listings(for: tab).isEmpty && (p.isLoadingFirstPage || p.isReloading)
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

    func requestLoadMore(for tab: SellerProfileTab, deps: AppDependencies, isGuestMode: Bool) {
        guard canLoadMore(for: tab) else { return }
        guard loadMoreTasks[tab.rawValue] == nil else { return }
        loadMoreTasks[tab.rawValue] = Task { @MainActor in
            defer { loadMoreTasks[tab.rawValue] = nil }
            await loadMoreListings(for: tab, deps: deps, isGuestMode: isGuestMode)
        }
    }

    func patchListingEngagement(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        patch(id, transform: transform)
    }

    private func pagination(for tab: SellerProfileTab) -> SellerTabPagination {
        tabPagination[tab.rawValue] ?? SellerTabPagination()
    }

    private func mutatePagination(for tab: SellerProfileTab, _ transform: (inout SellerTabPagination) -> Void) {
        var state = pagination(for: tab)
        transform(&state)
        tabPagination[tab.rawValue] = state
    }

    private func resolvedSellerId() -> String? {
        guard let id = activeSellerId?.trimmingCharacters(in: .whitespaces), !id.isEmpty else { return nil }
        return id
    }

    private func canLoadMore(for tab: SellerProfileTab) -> Bool {
        let p = pagination(for: tab)
        return p.hasMore
            && p.nextOffset > 0
            && !p.isLoadingMore
            && !p.isLoadingFirstPage
            && !p.isReloading
            && !isRefreshing
            && !listings(for: tab).isEmpty
    }

    private func reloadListingFeedOnRefresh(
        activeTab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool,
        generation: Int
    ) async {
        for tab in [SellerProfileTab.selling, SellerProfileTab.sold] where tab != activeTab {
            loadedListingTabs.remove(tab.rawValue)
            mutatePagination(for: tab) { $0 = SellerTabPagination() }
            setListings([], for: tab)
        }
        await fetchListingsFirstPage(
            activeTab,
            deps: deps,
            isGuestMode: isGuestMode,
            generation: generation,
            force: true
        )
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

    private func fetchListingsFirstPage(
        _ tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool,
        generation: Int,
        force: Bool
    ) async {
        guard generation == loadGeneration else { return }
        guard let sellerId = resolvedSellerId() else { return }

        if force {
            mutatePagination(for: tab) { state in
                state.fetchGeneration += 1
                state.hasMore = true
                state.nextOffset = 0
            }
        } else if loadedListingTabs.contains(tab.rawValue) {
            return
        }

        let pageGen = pagination(for: tab).fetchGeneration
        let hadItems = !listings(for: tab).isEmpty
        mutatePagination(for: tab) { state in
            if hadItems {
                state.isReloading = true
            } else {
                state.isLoadingFirstPage = true
            }
            state.isLoadingMore = false
        }

        let result = await fetchSellerListingsPage(
            sellerId: sellerId,
            tab: tab,
            offset: 0,
            deps: deps,
            isGuestMode: isGuestMode
        )
        guard generation == loadGeneration, pageGen == pagination(for: tab).fetchGeneration else { return }

        mutatePagination(for: tab) { state in
            state.isLoadingFirstPage = false
            state.isReloading = false
        }

        switch result {
        case .success(let payload):
            loadedListingTabs.insert(tab.rawValue)
            setListings(payload.items, for: tab)
            mutatePagination(for: tab) {
                $0.nextOffset = payload.rawCount
                $0.hasMore = payload.rawCount >= sellerListingPageSize
            }
            FeedListingImagePrefetch.prefetch(items: payload.items)
        case .failure:
            loadedListingTabs.remove(tab.rawValue)
            if !hadItems {
                setListings([], for: tab)
                mutatePagination(for: tab) { $0.hasMore = false }
            }
        }
    }

    private func loadMoreListings(
        for tab: SellerProfileTab,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async {
        guard canLoadMore(for: tab), let sellerId = resolvedSellerId() else { return }
        let now = Date()
        if let until = pagination(for: tab).loadMoreCooldownUntil, now < until { return }
        mutatePagination(for: tab) { $0.loadMoreCooldownUntil = now.addingTimeInterval(0.4) }

        let pageGen = pagination(for: tab).fetchGeneration
        let offset = pagination(for: tab).nextOffset
        guard offset > 0 else { return }

        mutatePagination(for: tab) { $0.isLoadingMore = true }
        defer { mutatePagination(for: tab) { $0.isLoadingMore = false } }

        let result = await fetchSellerListingsPage(
            sellerId: sellerId,
            tab: tab,
            offset: offset,
            deps: deps,
            isGuestMode: isGuestMode
        )
        guard pageGen == pagination(for: tab).fetchGeneration else { return }

        switch result {
        case .success(let payload):
            guard payload.rawCount > 0 else {
                mutatePagination(for: tab) { $0.hasMore = false }
                return
            }
            var seen = Set(listings(for: tab).map(\.id))
            let fresh = payload.items.filter { seen.insert($0.id).inserted }
            if !fresh.isEmpty {
                appendListings(fresh, for: tab)
                FeedListingImagePrefetch.prefetch(items: fresh)
            }
            mutatePagination(for: tab) { state in
                state.nextOffset += payload.rawCount
                state.hasMore = payload.rawCount >= sellerListingPageSize
            }
        case .failure:
            break
        }
    }

    private struct SellerListingsPagePayload {
        let items: [ListingFeedItem]
        let rawCount: Int
    }

    private func fetchSellerListingsPage(
        sellerId: String,
        tab: SellerProfileTab,
        offset: Int,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async -> Result<SellerListingsPagePayload, Error> {
        let status = tab == .sold ? "sold" : "active"
        var result = await deps.listingRepository.getListingsBySeller(
            sellerId: sellerId,
            status: status,
            limit: sellerListingPageSize,
            offset: offset,
            publicBrowse: isGuestMode
        )
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(350))
            result = await deps.listingRepository.getListingsBySeller(
                sellerId: sellerId,
                status: status,
                limit: sellerListingPageSize,
                offset: offset,
                publicBrowse: isGuestMode
            )
        }
        switch result {
        case .success(let rawPage):
            return .success(normalizeSellerListingsPage(rawPage, tab: tab))
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Cap client work when the API returns more than `limit` — keeps first paint fast on guest storefront.
    private func normalizeSellerListingsPage(
        _ rawPage: [ListingFeedItem],
        tab: SellerProfileTab
    ) -> SellerListingsPagePayload {
        let filtered: [ListingFeedItem]
        if tab == .selling {
            filtered = rawPage.filter { ($0.listingStatus ?? "").lowercased() != "sold" }
        } else {
            filtered = rawPage
        }
        let items = Array(filtered.prefix(sellerListingPageSize))
        let deliveredCount = min(rawPage.count, sellerListingPageSize)
        return SellerListingsPagePayload(items: items, rawCount: deliveredCount)
    }

    private func setListings(_ items: [ListingFeedItem], for tab: SellerProfileTab) {
        switch tab {
        case .selling: sellingListings = items
        case .sold: soldListings = items
        }
    }

    private func appendListings(_ items: [ListingFeedItem], for tab: SellerProfileTab) {
        switch tab {
        case .selling: sellingListings.append(contentsOf: items)
        case .sold: soldListings.append(contentsOf: items)
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
