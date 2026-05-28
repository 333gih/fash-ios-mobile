import Foundation
import Observation

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
    var loadError = false
    var isFollowing = false
    var followInFlight = false
    var selectedTab = 0

    private var activeKey: String?

    func loadForSeller(_ username: String, deps: AppDependencies, isGuestMode: Bool) async {
        let key = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !key.isEmpty else { return }
        if key == activeKey, profile != nil { return }
        activeKey = key
        if profile == nil || activeKey != key {
            profile = nil
            sellingListings = []
            soldListings = []
            sellerFocus = nil
            isFollowing = false
        }
        let showBlocking = profile == nil
        if showBlocking { isLoading = true }
        defer { if showBlocking { isLoading = false } }
        loadError = false

        async let tagsResult = deps.commonCatalogRepository.getAestheticTags(all: true)
        let profileResult: Result<ProfileInfo, Error> = if isGuestMode {
            await deps.userRepository.getProfilePublic(key)
        } else {
            await deps.userRepository.getProfile(key)
        }

        switch profileResult {
        case .success(let prof):
            profile = prof
            isFollowing = isGuestMode ? false : prof.isFollowing
            if case .success(let tags) = await tagsResult {
                aestheticCatalog = tags
            }
            await loadListings(sellerId: prof.userId, username: key, deps: deps, isGuestMode: isGuestMode)
            await loadSellerFocus(username: key, deps: deps, isGuestMode: isGuestMode)
        case .failure:
            loadError = true
        }
    }

    private func loadSellerFocus(username: String, deps: AppDependencies, isGuestMode: Bool) async {
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
            sellerFocus = focus.isEmpty ? nil : focus
        case .failure(let err):
            if err as? SellerFocusError == .forbidden {
                sellerFocusForbidden = true
            }
            sellerFocus = nil
        }
    }

    func toggleFollow(deps: AppDependencies, isGuestMode: Bool) async {
        guard !isGuestMode, let prof = profile, canFollow(deps: deps) else { return }
        let target = prof.username.nilIfEmpty ?? prof.userId
        guard !target.isEmpty else { return }
        followInFlight = true
        defer { followInFlight = false }
        let result: Result<Void, Error> = if isFollowing {
            await deps.userRepository.unfollow(target)
        } else {
            await deps.userRepository.follow(target)
        }
        guard case .success = result else { return }
        isFollowing.toggle()
        profile = copyProfile(prof, isFollowing: isFollowing, followerDelta: isFollowing ? 1 : -1)
    }

    func toggleLike(_ item: ListingFeedItem, deps: AppDependencies) async {
        guard case .success(let liked) = await deps.listingRepository.toggleLike(listingId: item.id) else { return }
        patch(item.id, liked: liked, saved: nil)
    }

    func toggleSave(_ item: ListingFeedItem, deps: AppDependencies) async {
        guard case .success(let saved) = await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: item.isSaved) else { return }
        patch(item.id, liked: nil, saved: saved)
    }

    func canFollow(deps: AppDependencies) -> Bool {
        guard let prof = profile,
              let myId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespaces),
              !myId.isEmpty else { return false }
        return myId.caseInsensitiveCompare(prof.userId) != .orderedSame
    }

    func canShowFollowUi() -> Bool {
        profile != nil
    }

    var listingsForSelectedTab: [ListingFeedItem] {
        selectedTab == 0 ? sellingListings : soldListings
    }

    private func loadListings(sellerId: String, username: String, deps: AppDependencies, isGuestMode: Bool) async {
        let id = sellerId.trimmingCharacters(in: .whitespaces).isEmpty ? username : sellerId
        async let active = deps.listingRepository.getListingsBySeller(
            sellerId: id, status: "active", limit: 50, publicBrowse: isGuestMode
        )
        async let sold = deps.listingRepository.getListingsBySeller(
            sellerId: id, status: "sold", limit: 50, publicBrowse: isGuestMode
        )
        if case .success(let list) = await active {
            sellingListings = list.filter { ($0.listingStatus ?? "").lowercased() != "sold" }
        }
        if case .success(let list) = await sold {
            soldListings = list
        }
    }

    private func patch(_ id: String, liked: Bool?, saved: Bool?) {
        func map(_ items: [ListingFeedItem]) -> [ListingFeedItem] {
            items.map { cur in
                guard cur.id == id else { return cur }
                if let liked {
                    let delta = (liked && !cur.isLiked) ? 1 : ((!liked && cur.isLiked) ? -1 : 0)
                    return ListingFeedItem(
                        id: cur.id, title: cur.title, coverImageUrl: cur.coverImageUrl, imageUrls: cur.imageUrls,
                        priceVnd: cur.priceVnd, brand: cur.brand, size: cur.size, categoryName: cur.categoryName,
                        listingAestheticTag: cur.listingAestheticTag, condition: cur.condition,
                        likeCount: max(0, cur.likeCount + delta), saveCount: cur.saveCount,
                        sellerId: cur.sellerId, sellerUsername: cur.sellerUsername, sellerStyleTag: cur.sellerStyleTag,
                        createdAt: cur.createdAt, isLiked: liked, isSaved: cur.isSaved,
                        onsiteInspectionCommitment: cur.onsiteInspectionCommitment,
                        listingStatus: cur.listingStatus, descriptionText: cur.descriptionText
                    )
                }
                if let saved {
                    let delta = (saved && !cur.isSaved) ? 1 : ((!saved && cur.isSaved) ? -1 : 0)
                    return ListingFeedItem(
                        id: cur.id, title: cur.title, coverImageUrl: cur.coverImageUrl, imageUrls: cur.imageUrls,
                        priceVnd: cur.priceVnd, brand: cur.brand, size: cur.size, categoryName: cur.categoryName,
                        listingAestheticTag: cur.listingAestheticTag, condition: cur.condition,
                        likeCount: cur.likeCount, saveCount: max(0, cur.saveCount + delta),
                        sellerId: cur.sellerId, sellerUsername: cur.sellerUsername, sellerStyleTag: cur.sellerStyleTag,
                        createdAt: cur.createdAt, isLiked: cur.isLiked, isSaved: saved,
                        onsiteInspectionCommitment: cur.onsiteInspectionCommitment,
                        listingStatus: cur.listingStatus, descriptionText: cur.descriptionText
                    )
                }
                return cur
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
