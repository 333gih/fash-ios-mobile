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

@Observable
@MainActor
final class ProductDetailViewModel {
    var detail: ListingDetail?
    var sellerProfile: ProfileInfo?
    var moreFromSeller: [ListingFeedItem] = []
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
        if !activeListingId.isEmpty, !activeListingId.caseInsensitiveCompare(id).orderedSame {
            deps.realtimeManager.unsubscribeFromListing(activeListingId)
        }
        activeListingId = id
        detail = nil
        sellerProfile = nil
        moreFromSeller = []
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
            if let sid = d.sellerId?.nilIfEmpty ?? d.sellerUsername?.nilIfEmpty {
                await loadSellerAndMore(sellerKey: sid, excludeListingId: id, publicBrowse: guestBrowse, deps: deps)
            }
            if !guestBrowse {
                _ = await deps.listingRepository.recordView(listingId: id)
                maybeShowPurchaseGuide(d, deps: deps)
                startListingRealtime(listingId: id, deps: deps)
            }
        case .failure(let error):
            loadError = FashErrorPresentation.userMessage(for: error)
        }
        isLoading = false
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
        switch await deps.listingRepository.toggleLike(listingId: d.id) {
        case .success(let liked):
            let delta = (liked && !d.isLiked) ? 1 : ((!liked && d.isLiked) ? -1 : 0)
            detail = d.copyMutating(isLiked: liked, likeCount: max(0, d.likeCount + delta))
            if liked { deps.feedEventReporter.like(listingId: d.id, surface: "pdp") }
            snackbarMessage = FeedEngagementFeedback.likeMessage(liked: liked)
        case .failure(let error):
            snackbarMessage = FeedEngagementFeedback.actionErrorMessage(for: error)
        }
    }

    func toggleSave(deps: AppDependencies) async -> Bool {
        guard let d = detail else { return false }
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
        guard let match = orders.first(where: {
            $0.listingId.caseInsensitiveCompare(listingId) == .orderedSame
                && activeStatuses.contains($0.status.lowercased())
        }) else { return nil }
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
        let moreResult = await deps.listingRepository.getListingsBySeller(
            sellerId: sellerKey,
            limit: 5,
            offset: 0,
            publicBrowse: publicBrowse
        )
        if case .success(let list) = moreResult {
            moreFromSeller = list.filter { !$0.id.caseInsensitiveCompare(excludeListingId).orderedSame }.prefix(5).map { $0 }
        } else {
            moreFromSeller = []
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
