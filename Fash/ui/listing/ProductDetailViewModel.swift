import Foundation
import Observation

struct BuyerActiveOrder: Equatable {
    let orderId: String
    let amountVnd: Int64
    let status: String
}

enum ProductBottomBarMode: Equatable {
    case normal
    case reservedOther
    case reservedBuyer
    case sold
}

enum ProductDetailDiscoveryConstants {
    static let sellerRailLimit = 10
    static let relatedRailLimit = 8
    /// Merged Pinterest grid on PDP (deduped across seller / category / brand / style).
    static let mergedDiscoveryLimit = 24
}

@Observable
@MainActor
final class ProductDetailViewModel {
    var detail: ListingDetail?
    var sellerProfile: ProfileInfo?
    var moreFromSeller: [ListingFeedItem] = []
    var relatedByCategory: [ListingFeedItem] = []
    var relatedByBrand: [ListingFeedItem] = []
    var relatedByStyle: [ListingFeedItem] = []
    /// Single Explore-style masonry feed with per-card relation badge.
    var discoveryFeed: [ProductDiscoveryFeedEntry] = []
    /// True while seller/category/brand/style rails load after main detail is shown.
    var isDiscoveryLoading = false
    var isLoading = false
    var loadError: String?
    var isFollowing = false
    var bottomBarMode: ProductBottomBarMode = .normal
    var buyerActiveOrder: BuyerActiveOrder?
    var showPurchaseGuide = false
    var isOpeningChat = false
    var snackbarMessage: String?
    var galleryIndex = 0

    private var activeListingId = ""
    private var realtimeListenerId: UUID?
    private let guideStore = ProductDetailGuideStore()

    var resolvedImageUrls: [String] {
        guard let detail else { return [] }
        return detail.imageUrls.compactMap { FeedImageUrl.resolveListingImageUrlOrNil($0) }
    }

    func load(listingId: String, deps: AppDependencies) async {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            loadError = L10n.productDetailError
            isLoading = false
            return
        }
        if let realtimeListenerId {
            deps.realtimeManager.removeEventListener(realtimeListenerId)
            self.realtimeListenerId = nil
        }
        if !activeListingId.isEmpty, activeListingId.caseInsensitiveCompare(id) != .orderedSame {
            deps.realtimeManager.unsubscribeFromListing(activeListingId)
        }
        activeListingId = id
        detail = nil
        sellerProfile = nil
        moreFromSeller = []
        relatedByCategory = []
        relatedByBrand = []
        relatedByStyle = []
        discoveryFeed = []
        isDiscoveryLoading = false
        bottomBarMode = .normal
        buyerActiveOrder = nil
        showPurchaseGuide = false
        isOpeningChat = false
        galleryIndex = 0
        isLoading = true
        loadError = nil

        let guestBrowse = deps.isGuestBrowseActive
        switch await deps.listingRepository.getListingDetailFull(listingId: id, publicBrowse: guestBrowse) {
        case .success(let d):
            detail = d
            isFollowing = d.sellerIsFollowing ?? false
            applyBottomModeFromDetail(d, listingId: id, deps: deps)
            isLoading = false
            let sid = d.sellerId?.nilIfEmpty ?? d.sellerUsername?.nilIfEmpty
            Task { @MainActor in
                await self.loadPostDetailSideEffects(
                    listingId: id,
                    detail: d,
                    sellerKey: sid,
                    publicBrowse: guestBrowse,
                    deps: deps
                )
            }
        case .failure(let error):
            loadError = FashErrorPresentation.userMessage(for: error)
            isDiscoveryLoading = false
            isLoading = false
        }
    }

    /// Discovery rails, view record, and realtime — after PDP shell is visible.
    private func loadPostDetailSideEffects(
        listingId id: String,
        detail d: ListingDetail,
        sellerKey sid: String?,
        publicBrowse guestBrowse: Bool,
        deps: AppDependencies
    ) async {
        if let sid {
            isDiscoveryLoading = true
            await loadSellerAndMore(sellerKey: sid, excludeListingId: id, publicBrowse: guestBrowse, deps: deps)
        } else {
            isDiscoveryLoading = false
        }
        if !guestBrowse {
            _ = await deps.listingRepository.recordView(listingId: id)
            maybeShowPurchaseGuide(d, deps: deps)
            startListingRealtime(listingId: id, deps: deps)
        }
    }

    func clearForSignedOut(deps: AppDependencies) {
        if let realtimeListenerId {
            deps.realtimeManager.removeEventListener(realtimeListenerId)
            self.realtimeListenerId = nil
        }
        if !activeListingId.isEmpty {
            deps.realtimeManager.unsubscribeFromListing(activeListingId)
        }
        activeListingId = ""
        detail = nil
        sellerProfile = nil
        moreFromSeller = []
        relatedByCategory = []
        relatedByBrand = []
        relatedByStyle = []
        discoveryFeed = []
        isLoading = false
        loadError = nil
        isFollowing = false
        bottomBarMode = .normal
        buyerActiveOrder = nil
        showPurchaseGuide = false
        isOpeningChat = false
    }

    func dismissPurchaseGuide(deps: AppDependencies) {
        if let uid = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines), !uid.isEmpty {
            guideStore.markPurchaseGuideSeen(userId: uid)
        }
        showPurchaseGuide = false
    }

    func reportShare(deps: AppDependencies) {
        guard let id = detail?.id else { return }
        deps.feedEventReporter.share(listingId: id, surface: "pdp")
    }

    func reportChatInitiate(deps: AppDependencies) {
        guard let id = detail?.id else { return }
        deps.feedEventReporter.chatInitiate(listingId: id, surface: "pdp")
    }

    func toggleLike(deps: AppDependencies) async {
        guard let d = detail else { return }
        await toggleLike(itemId: d.id, snapshot: nil, deps: deps, surface: "pdp")
    }

    func toggleLikeRailItem(_ item: ListingFeedItem, deps: AppDependencies) async {
        await toggleLike(itemId: item.id, snapshot: item, deps: deps, surface: "pdp_rail")
    }

    func toggleSaveRailItem(_ item: ListingFeedItem, deps: AppDependencies) async {
        guard deps.listingEngagement.beginSaveToggle(listingId: item.id) else { return }
        patchRails(item.id) { _ in item.toggledSave }
        defer { deps.listingEngagement.endSaveToggle(listingId: item.id) }
        switch await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: item.isSaved) {
        case .success(let saved):
            patchRails(item.id) { _ in item.applyingSaveToggle(saved) }
            if saved { deps.feedEventReporter.save(listingId: item.id, surface: "pdp_rail") }
            deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
        case .failure(let error):
            patchRails(item.id) { _ in item }
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        }
    }

    func toggleSave(deps: AppDependencies) async -> Bool {
        guard let d = detail else { return false }
        guard deps.listingEngagement.beginSaveToggle(listingId: d.id) else { return d.isSaved }
        defer { deps.listingEngagement.endSaveToggle(listingId: d.id) }
        switch await deps.listingRepository.toggleSave(listingId: d.id, currentlySaved: d.isSaved) {
        case .success(let saved):
            let delta = (saved && !d.isSaved) ? 1 : ((!saved && d.isSaved) ? -1 : 0)
            detail = d.copyMutating(isSaved: saved, saveCount: max(0, d.saveCount + delta))
            if saved { deps.feedEventReporter.save(listingId: d.id, surface: "pdp") }
            snackbarMessage = FeedEngagementFeedback.saveMessage(saved: saved)
            return saved && delta > 0
        case .failure(let error):
            snackbarMessage = FeedEngagementFeedback.actionErrorMessage(for: error)
            return false
        }
    }

    func follow(deps: AppDependencies) async {
        guard let target = followTarget else { return }
        switch await deps.userRepository.follow(target) {
        case .success:
            isFollowing = true
            detail = detail?.copyMutating(sellerIsFollowing: true)
            if let id = detail?.id {
                deps.feedEventReporter.followSeller(listingId: id, surface: "pdp")
            }
            deps.showSnackbar(L10n.followSuccess)
            snackbarMessage = L10n.followSuccess
        case .failure(let error):
            let msg = FeedEngagementFeedback.actionErrorMessage(for: error)
            deps.showSnackbar(msg)
            snackbarMessage = msg
        }
    }

    func unfollow(deps: AppDependencies) async {
        guard let target = followTarget else { return }
        switch await deps.userRepository.unfollow(target) {
        case .success:
            isFollowing = false
            detail = detail?.copyMutating(sellerIsFollowing: false)
        case .failure(let error):
            snackbarMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func openChat(deps: AppDependencies) async -> String? {
        guard let item = detail else { return nil }
        isOpeningChat = true
        defer { isOpeningChat = false }
        reportChatInitiate(deps: deps)
        switch await deps.chatRepository.startConversation(listingId: item.id) {
        case .success(let convId):
            return convId
        case .failure(let error):
            snackbarMessage = FashErrorPresentation.userMessage(for: error)
            return nil
        }
    }

    func findBuyerActiveOrder(listingId: String, deps: AppDependencies) async -> BuyerActiveOrder? {
        await loadBuyerActiveOrder(listingId: listingId, deps: deps)
    }

    private var followTarget: String? {
        guard let d = detail else { return nil }
        return d.sellerId?.nilIfEmpty ?? d.sellerUsername?.nilIfEmpty
    }

    private func applyBottomModeFromDetail(_ d: ListingDetail, listingId: String, deps: AppDependencies) {
        switch d.status.lowercased() {
        case "sold":
            bottomBarMode = .sold
            buyerActiveOrder = nil
        case "reserved":
            bottomBarMode = .reservedOther
            buyerActiveOrder = nil
            Task {
                if let active = await loadBuyerActiveOrder(listingId: listingId, deps: deps) {
                    buyerActiveOrder = active
                    bottomBarMode = .reservedBuyer
                }
            }
        default:
            bottomBarMode = .normal
            buyerActiveOrder = nil
        }
    }

    private func maybeShowPurchaseGuide(_ d: ListingDetail, deps: AppDependencies) {
        let uid = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !uid.isEmpty, !guideStore.hasSeenPurchaseGuide(userId: uid) else { return }
        guard d.status.lowercased() != "sold" else { return }
        showPurchaseGuide = true
    }

    private func startListingRealtime(listingId: String, deps: AppDependencies) {
        deps.realtimeManager.subscribeToListing(listingId)
        if let realtimeListenerId {
            deps.realtimeManager.removeEventListener(realtimeListenerId)
        }
        realtimeListenerId = deps.realtimeManager.addEventListener { [weak self] event in
            guard let self else { return }
            switch event {
            case .listingReserved(let lid) where self.listingIdMatches(lid):
                self.detail = self.detail?.copyMutating(status: "reserved")
                self.bottomBarMode = .reservedOther
                self.buyerActiveOrder = nil
                Task {
                    if let active = await self.loadBuyerActiveOrder(listingId: listingId, deps: deps) {
                        self.buyerActiveOrder = active
                        self.bottomBarMode = .reservedBuyer
                    }
                }
            case .listingAvailable(let lid) where self.listingIdMatches(lid):
                self.detail = self.detail?.copyMutating(status: "active")
                self.bottomBarMode = .normal
                self.buyerActiveOrder = nil
                self.snackbarMessage = L10n.productListingAvailableSnackbar
            case .listingSold(let lid) where self.listingIdMatches(lid):
                self.detail = self.detail?.copyMutating(status: "sold")
                self.bottomBarMode = .sold
            default:
                break
            }
        }
    }

    private func listingIdMatches(_ id: String) -> Bool {
        !id.isEmpty && activeListingId.caseInsensitiveCompare(id.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }

    private func loadBuyerActiveOrder(listingId: String, deps: AppDependencies) async -> BuyerActiveOrder? {
        let myId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !myId.isEmpty else { return nil }
        guard case .success(let orders) = await deps.orderRepository.getBuyingOrders(limit: 50, offset: 0) else {
            return nil
        }
        let activeStatuses: Set<String> = [
            "payment_pending", "payment_held", "in_transit", "pending",
            "cash_meetup_open", "fulfillment_pending",
        ]
        let match = orders.first(where: { order in
            order.listingId.caseInsensitiveCompare(listingId) == .orderedSame
                && activeStatuses.contains(order.status.lowercased())
        })
        guard let match else { return nil }
        return BuyerActiveOrder(orderId: match.orderId, amountVnd: match.priceVnd, status: match.status)
    }

    private func loadSellerAndMore(
        sellerKey: String,
        excludeListingId: String,
        publicBrowse: Bool,
        deps: AppDependencies
    ) async {
        let profileId = detail?.sellerUsername?.nilIfEmpty ?? sellerKey
        let profileResult = publicBrowse
            ? await deps.userRepository.getProfilePublic(profileId)
            : await deps.userRepository.getProfile(profileId)
        if case .success(let profile) = profileResult {
            sellerProfile = profile
            if detail?.sellerIsFollowing == nil, profile.isFollowing {
                isFollowing = true
            }
        }

        guard let detail else {
            isDiscoveryLoading = false
            return
        }
        isDiscoveryLoading = true
        defer { isDiscoveryLoading = false }
        async let sellerRail = loadSellerRail(
            sellerKey: sellerKey,
            excludeListingId: excludeListingId,
            publicBrowse: publicBrowse,
            deps: deps
        )
        async let categoryRail = loadRelatedRail(
            detail: detail,
            excludeListingId: excludeListingId,
            publicBrowse: publicBrowse,
            deps: deps,
            categoryId: detail.categoryId?.nilIfEmpty
        )
        async let brandRail = loadRelatedRail(
            detail: detail,
            excludeListingId: excludeListingId,
            publicBrowse: publicBrowse,
            deps: deps,
            brandId: detail.brandId?.nilIfEmpty
        )
        let tagIds = detail.aestheticTagRefs.compactMap(\.id?.nilIfEmpty)
        async let styleRail = loadRelatedRail(
            detail: detail,
            excludeListingId: excludeListingId,
            publicBrowse: publicBrowse,
            deps: deps,
            aestheticTagIds: tagIds.isEmpty ? nil : tagIds
        )
        moreFromSeller = await sellerRail
        relatedByCategory = await categoryRail
        relatedByBrand = await brandRail
        relatedByStyle = await styleRail
        let sellerBadge = detail.sellerUsername?.nilIfEmpty.map { "@\($0)" }
            ?? detail.sellerDisplayName?.nilIfEmpty
            ?? L10n.productRelationBadgeSeller
        discoveryFeed = ProductDiscoveryFeedBuilder.merge(
            detail: detail,
            sellerLabel: sellerBadge,
            sellerItems: moreFromSeller,
            categoryLabel: detail.category?.nilIfEmpty ?? detail.parentCategoryName?.nilIfEmpty,
            categoryItems: relatedByCategory,
            brandLabel: detail.brand?.nilIfEmpty,
            brandItems: relatedByBrand,
            styleItems: relatedByStyle
        )
    }

    private func loadSellerRail(
        sellerKey: String,
        excludeListingId: String,
        publicBrowse: Bool,
        deps: AppDependencies
    ) async -> [ListingFeedItem] {
        let moreResult = await deps.listingRepository.getListingsBySeller(
            sellerId: sellerKey,
            status: "active",
            limit: ProductDetailDiscoveryConstants.sellerRailLimit,
            offset: 0,
            publicBrowse: publicBrowse
        )
        guard case .success(let list) = moreResult else { return [] }
        return list
            .filter { ($0.listingStatus ?? "").lowercased() != "sold" }
            .filter { $0.id.caseInsensitiveCompare(excludeListingId) != .orderedSame }
    }

    private func loadRelatedRail(
        detail: ListingDetail,
        excludeListingId: String,
        publicBrowse: Bool,
        deps: AppDependencies,
        categoryId: String? = nil,
        brandId: String? = nil,
        aestheticTagIds: [String]? = nil
    ) async -> [ListingFeedItem] {
        if categoryId == nil, brandId == nil, aestheticTagIds == nil { return [] }
        let result: Result<[ListingFeedItem], Error>
        if publicBrowse {
            result = await deps.searchRepository.browseListings(
                categoryId: categoryId,
                aestheticTagIds: aestheticTagIds,
                brandId: brandId,
                limit: ProductDetailDiscoveryConstants.relatedRailLimit,
                offset: 0
            )
        } else {
            result = await deps.searchRepository.searchListings(
                categoryId: categoryId,
                aestheticTagIds: aestheticTagIds,
                brandId: brandId,
                sort: "recent",
                limit: ProductDetailDiscoveryConstants.relatedRailLimit,
                offset: 0
            )
        }
        guard case .success(let list) = result else { return [] }
        return list.filter { $0.id.caseInsensitiveCompare(excludeListingId) != .orderedSame }
    }

    private func toggleLike(
        itemId: String,
        snapshot: ListingFeedItem?,
        deps: AppDependencies,
        surface: String
    ) async {
        guard deps.listingEngagement.beginLikeToggle(listingId: itemId) else { return }
        if let snapshot {
            patchRails(itemId) { _ in snapshot.toggledLike }
        }
        defer { deps.listingEngagement.endLikeToggle(listingId: itemId) }
        switch await deps.listingRepository.toggleLike(listingId: itemId) {
        case .success(let liked):
            if let snapshot {
                patchRails(itemId) { _ in snapshot.applyingLikeToggle(liked) }
            }
            if let d = detail, itemId == d.id {
                let delta = (liked && !d.isLiked) ? 1 : ((!liked && d.isLiked) ? -1 : 0)
                detail = d.copyMutating(isLiked: liked, likeCount: max(0, d.likeCount + delta))
            }
            if liked { deps.feedEventReporter.like(listingId: itemId, surface: surface) }
            let message = FeedEngagementFeedback.likeMessage(liked: liked)
            if itemId == detail?.id {
                snackbarMessage = message
            } else {
                deps.showSnackbar(message)
            }
        case .failure(let error):
            if let snapshot {
                patchRails(itemId) { _ in snapshot }
            }
            let message = FeedEngagementFeedback.actionErrorMessage(for: error)
            if itemId == detail?.id {
                snackbarMessage = message
            } else {
                deps.showSnackbar(message)
            }
        }
    }

    private func patchRails(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        func map(_ items: [ListingFeedItem]) -> [ListingFeedItem] {
            items.map { $0.id == id ? transform($0) : $0 }
        }
        moreFromSeller = map(moreFromSeller)
        relatedByCategory = map(relatedByCategory)
        relatedByBrand = map(relatedByBrand)
        relatedByStyle = map(relatedByStyle)
        discoveryFeed = discoveryFeed.map { entry in
            guard entry.item.id == id else { return entry }
            return ProductDiscoveryFeedEntry(
                item: transform(entry.item),
                relation: entry.relation,
                relationLabel: entry.relationLabel
            )
        }
    }
}

private extension ListingDetail {
    func copyMutating(
        isLiked: Bool? = nil,
        isSaved: Bool? = nil,
        likeCount: Int? = nil,
        saveCount: Int? = nil,
        status: String? = nil,
        sellerIsFollowing: Bool?? = nil
    ) -> ListingDetail {
        var c = self
        if let isLiked { c.isLiked = isLiked }
        if let isSaved { c.isSaved = isSaved }
        if let likeCount { c.likeCount = likeCount }
        if let saveCount { c.saveCount = saveCount }
        if let status { c.status = status }
        if let sellerIsFollowing { c.sellerIsFollowing = sellerIsFollowing }
        return c
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
