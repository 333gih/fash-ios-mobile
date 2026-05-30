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
    var selectedTab = SellerProfileTab.selling.rawValue

    private var activeKey: String?
    private var loadGeneration = 0

    func loadForSeller(_ username: String, deps: AppDependencies, isGuestMode: Bool) async {
        let key = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !key.isEmpty else { return }
        if key == activeKey, profile != nil { return }

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
        }
        let showBlocking = profile == nil
        if showBlocking { isLoading = true }
        defer {
            guard generation == loadGeneration else { return }
            if showBlocking { isLoading = false }
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
            await loadListings(
                sellerId: prof.userId,
                username: key,
                deps: deps,
                isGuestMode: isGuestMode,
                generation: generation
            )
            await loadSellerFocus(
                username: key,
                deps: deps,
                isGuestMode: isGuestMode,
                generation: generation
            )
        case .failure:
            guard generation == loadGeneration else { return }
            loadError = true
        }
    }

    private func fetchSellerProfileWithRetry(
        key: String,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async -> Result<ProfileInfo, Error> {
        func once() async -> Result<ProfileInfo, Error> {
            if isGuestMode {
                await deps.userRepository.getProfilePublic(key)
            } else {
                await deps.userRepository.getProfile(key)
            }
        }
        var result = await once()
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(400))
            result = await once()
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
        switch await deps.listingRepository.toggleLike(listingId: item.id) {
        case .success(let liked):
            patch(item.id, liked: liked, saved: nil)
            if liked {
                deps.feedEventReporter.like(listingId: item.id, surface: "seller_profile")
            }
            deps.showSnackbar(FeedEngagementFeedback.likeMessage(liked: liked))
        case .failure(let error):
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        }
    }

    func toggleSave(_ item: ListingFeedItem, deps: AppDependencies) async {
        switch await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: item.isSaved) {
        case .success(let saved):
            patch(item.id, liked: nil, saved: saved)
            if saved {
                deps.feedEventReporter.save(listingId: item.id, surface: "seller_profile")
            }
            deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
        case .failure(let error):
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
        switch SellerProfileTab(rawValue: selectedTab) ?? .selling {
        case .sold: return soldListings
        case .selling: return sellingListings
        }
    }

    private func loadListings(
        sellerId: String,
        username: String,
        deps: AppDependencies,
        isGuestMode: Bool,
        generation: Int
    ) async {
        let id = sellerId.trimmingCharacters(in: .whitespaces).isEmpty ? username : sellerId
        async let active = fetchSellerListingsWithRetry(
            sellerId: id,
            status: "active",
            deps: deps,
            isGuestMode: isGuestMode
        )
        async let sold = fetchSellerListingsWithRetry(
            sellerId: id,
            status: "sold",
            deps: deps,
            isGuestMode: isGuestMode
        )
        guard generation == loadGeneration else { return }
        if case .success(let list) = await active {
            guard generation == loadGeneration else { return }
            sellingListings = list.filter { ($0.listingStatus ?? "").lowercased() != "sold" }
        }
        if case .success(let list) = await sold {
            guard generation == loadGeneration else { return }
            soldListings = list
        }
    }

    private func fetchSellerListingsWithRetry(
        sellerId: String,
        status: String,
        deps: AppDependencies,
        isGuestMode: Bool
    ) async -> Result<[ListingFeedItem], Error> {
        func once() async -> Result<[ListingFeedItem], Error> {
            await deps.listingRepository.getListingsBySeller(
                sellerId: sellerId,
                status: status,
                limit: 50,
                publicBrowse: isGuestMode
            )
        }
        var result = await once()
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(350))
            result = await once()
        }
        return result
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
