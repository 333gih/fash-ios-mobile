import Foundation
import Observation

private let profileStaleThresholdSeconds: TimeInterval = 60

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

    var sellingListings: [ListingFeedItem] = []
    var inReviewListings: [ListingFeedItem] = []
    var rejectedListings: [ListingFeedItem] = []
    var soldListings: [ListingFeedItem] = []
    var wishlistListings: [ListingFeedItem] = []

    private var lastSuccessfulRefreshAt: Date?

    func listings(for tab: ProfileListingTab) -> [ListingFeedItem] {
        switch tab {
        case .active: return sellingListings
        case .inReview: return inReviewListings
        case .rejected: return rejectedListings
        case .sold: return soldListings
        case .wishlist: return wishlistListings
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
        if showBlocking { isLoading = true } else { isRefreshing = true }
        loadError = false
        defer { isLoading = false; isRefreshing = false }

        async let profileResult = deps.userRepository.getMeProfile()
        async let tagsResult = deps.commonCatalogRepository.getAestheticTags(all: true)
        switch await profileResult {
        case .success(let p):
            applyProfile(p)
            lastSuccessfulRefreshAt = Date()
            loadError = false
            if case .success(let tags) = await tagsResult {
                aestheticCatalog = tags
            }
            await loadListings(deps: deps)
        case .failure:
            loadError = true
        }
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

    private func loadListings(deps: AppDependencies) async {
        async let mineResult = deps.listingRepository.getMyListings(limit: 50, offset: 0)
        async let wishResult = deps.listingRepository.getWishlistListings(limit: 50, offset: 0)
        let allMine = (try? await mineResult.get()) ?? []
        let wish = (try? await wishResult.get()) ?? []
        sellingListings = allMine.filter { $0.isActiveListing() }
        inReviewListings = allMine.filter { $0.isInReviewListing() }
        rejectedListings = allMine.filter { $0.isRejectedListing() }
        soldListings = allMine.filter { $0.isSoldListingStatus() }
        wishlistListings = wish
        if soldCount == 0 { soldCount = soldListings.count }
        if productCount == 0 {
            productCount = sellingListings.count + inReviewListings.count + rejectedListings.count
        }
    }

    func toggleLike(_ item: ListingFeedItem, deps: AppDependencies) async {
        guard case .success(let liked) = await deps.listingRepository.toggleLike(listingId: item.id) else { return }
        patchListing(item.id) { cur in
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
    }

    func toggleSave(_ item: ListingFeedItem, deps: AppDependencies) async {
        guard case .success(let saved) = await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: item.isSaved) else { return }
        patchListing(item.id) { cur in
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
        if !saved && item.isSaved {
            wishlistListings.removeAll { $0.id == item.id }
        } else if saved {
            if let updated = sellingListings.first(where: { $0.id == item.id })
                ?? inReviewListings.first(where: { $0.id == item.id })
                ?? rejectedListings.first(where: { $0.id == item.id })
                ?? soldListings.first(where: { $0.id == item.id }) {
                if !wishlistListings.contains(where: { $0.id == item.id }) {
                    wishlistListings.append(updated)
                }
            }
        }
    }

    private func patchListing(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        sellingListings = sellingListings.map { $0.id == id ? transform($0) : $0 }
        inReviewListings = inReviewListings.map { $0.id == id ? transform($0) : $0 }
        rejectedListings = rejectedListings.map { $0.id == id ? transform($0) : $0 }
        soldListings = soldListings.map { $0.id == id ? transform($0) : $0 }
        wishlistListings = wishlistListings.map { $0.id == id ? transform($0) : $0 }
    }

    func requestInReviewTabFromHome(deps: AppDependencies) async {
        await refresh(deps: deps, force: true)
    }
}
