import Foundation

extension UserRepository {
    func getMyFollowing(limit: Int = 20, offset: Int = 0) async -> Result<FollowListPage, Error> {
        await getMyFollowList(pathSegment: "following", limit: limit, offset: offset)
    }

    func getMyFollowers(limit: Int = 20, offset: Int = 0) async -> Result<FollowListPage, Error> {
        await getMyFollowList(pathSegment: "followers", limit: limit, offset: offset)
    }

    private func getMyFollowList(pathSegment: String, limit: Int, offset: Int) async -> Result<FollowListPage, Error> {
        let capped = min(max(limit, 1), 100)
        let safeOffset = max(0, offset)
        let path = "api/v1/users/me/\(pathSegment)?limit=\(capped)&offset=\(safeOffset)"
        do {
            let data = try await RepositoryHttp.executeCoreGet(relativePath: path, client: client)
            return .success(parseFollowListEnvelope(data, requestLimit: capped, requestOffset: safeOffset))
        } catch {
            return .failure(error)
        }
    }

    private func parseFollowListEnvelope(_ data: Data, requestLimit: Int, requestOffset: Int) -> FollowListPage {
        guard let root = try? RepositoryHttp.jsonObject(data) else {
            return FollowListPage(items: [], total: 0)
        }
        var rows: [[String: Any]] = []
        if let arr = root["items"] as? [[String: Any]] {
            rows = arr
        } else if let arr = root["data"] as? [[String: Any]] {
            rows = arr
        } else if let arr = root["users"] as? [[String: Any]] {
            rows = arr
        } else if let arr = root["following"] as? [[String: Any]] {
            rows = arr
        } else if let arr = root["followers"] as? [[String: Any]] {
            rows = arr
        }
        let items = rows.map(parseUserSearchResult)
        let total = RepositoryHttp.optInt(root, "total", default: items.count)
        _ = RepositoryHttp.optInt(root, "limit", default: requestLimit)
        _ = RepositoryHttp.optInt(root, "offset", default: requestOffset)
        return FollowListPage(items: items, total: total)
    }

    private func parseUserSearchResult(_ o: [String: Any]) -> UserSearchResult {
        UserSearchResult(
            userId: RepositoryHttp.optString(o, "user_id", "UserID", "id", "ID"),
            username: RepositoryHttp.optString(o, "username", "Username"),
            displayName: RepositoryHttp.optString(o, "display_name", "DisplayName", "name", "Name"),
            avatarUrl: RepositoryHttp.optString(o, "avatar_url", "AvatarURL"),
            followerCount: RepositoryHttp.optInt(o, "follower_count", "FollowerCount"),
            verified: RepositoryHttp.optBool(o, "verified", "Verified"),
            followingCount: RepositoryHttp.optInt(o, "following_count", "FollowingCount"),
            listingCount: RepositoryHttp.optInt(o, "listing_count", "ListingCount", "product_count", "ProductCount")
        )
    }
}
