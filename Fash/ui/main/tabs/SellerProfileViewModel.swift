import Foundation
import Observation

@Observable
@MainActor
final class SellerProfileViewModel {
    var profile: ProfileInfo?
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
            isFollowing = false
        }
        let showBlocking = profile == nil
        if showBlocking { isLoading = true }
        defer { if showBlocking { isLoading = false } }
        loadError = false
        let profileResult: Result<ProfileInfo, Error>
        if isGuestMode {
            profileResult = await deps.userRepository.getProfilePublic(key)
        } else {
            profileResult = await deps.userRepository.getProfile(key)
        }
        switch profileResult {
        case .success(let prof):
            profile = prof
            isFollowing = isGuestMode ? false : prof.isFollowing
            if let sellerId = prof.userId.nilIfEmpty {
                await loadListings(sellerId: sellerId, deps: deps, isGuestMode: isGuestMode)
            }
        case .failure:
            loadError = true
        }
    }

    func toggleFollow(deps: AppDependencies, isGuestMode: Bool) async {
        guard !isGuestMode, let prof = profile, canFollow(deps: deps) else { return }
        let target = prof.username.nilIfEmpty ?? prof.userId
        guard !target.isEmpty else { return }
        followInFlight = true
        defer { followInFlight = false }
        let result: Result<Void, Error>
        if isFollowing {
            result = await deps.userRepository.unfollow(target)
        } else {
            result = await deps.userRepository.follow(target)
        }
        guard case .success = result else { return }
        isFollowing.toggle()
        profile = ProfileInfo(
            userId: prof.userId,
            username: prof.username,
            displayName: prof.displayName,
            avatarUrl: prof.avatarUrl,
            coverImageUrl: prof.coverImageUrl,
            followerCount: max(0, prof.followerCount + (isFollowing ? 1 : -1)),
            followingCount: prof.followingCount,
            productCount: prof.productCount,
            bio: prof.bio,
            isFollowing: isFollowing
        )
    }

    func canFollow(deps: AppDependencies) -> Bool {
        guard let prof = profile,
              let myId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespaces),
              !myId.isEmpty else { return false }
        return myId.caseInsensitiveCompare(prof.userId) != .orderedSame
    }

    var listingsForSelectedTab: [ListingFeedItem] {
        selectedTab == 0 ? sellingListings : soldListings
    }

    private func loadListings(sellerId: String, deps: AppDependencies, isGuestMode: Bool) async {
        async let active = deps.listingRepository.getListingsBySeller(
            sellerId: sellerId, status: "active", limit: 50, publicBrowse: isGuestMode
        )
        async let sold = deps.listingRepository.getListingsBySeller(
            sellerId: sellerId, status: "sold", limit: 50, publicBrowse: isGuestMode
        )
        if case .success(let list) = await active {
            sellingListings = list.filter { ($0.listingStatus ?? "").lowercased() != "sold" }
        }
        if case .success(let list) = await sold {
            soldListings = list
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
