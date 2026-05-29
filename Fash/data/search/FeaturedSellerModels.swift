import Foundation

struct FeaturedSellerItem: Equatable, Identifiable {
    let userId: String
    let username: String
    let displayName: String
    let bio: String
    let avatarUrl: String
    let followerCount: Int
    let listingCount: Int
    let averageRating: Float?
    let verified: Bool
    let previewListingIds: [String]

    var id: String { userId.isEmpty ? username : userId }

    var sellerKey: String {
        let uid = userId.trimmingCharacters(in: .whitespaces)
        if !uid.isEmpty { return uid }
        return username.trimmingCharacters(in: .whitespaces)
    }

    /// Android `FeaturedSellerItem.toUserSearchResult()`.
    func toUserSearchResult() -> UserSearchResult {
        UserSearchResult(
            userId: userId,
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
            followerCount: followerCount,
            verified: verified,
            followingCount: 0,
            listingCount: listingCount
        )
    }
}

struct FeaturedSellersPage: Equatable {
    let items: [FeaturedSellerItem]
    let total: Int
}

enum FeaturedSellerParser {
    static func parse(_ data: Data) -> [FeaturedSellerItem] {
        guard let raw = String(data: data, encoding: .utf8) else { return [] }
        return parse(raw)
    }

    static func parsePage(_ data: Data) -> FeaturedSellersPage {
        let trimmed = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty, let json = trimmed.data(using: .utf8) else {
            return FeaturedSellersPage(items: [], total: 0)
        }
        if trimmed.hasPrefix("[") {
            let items = parse(trimmed)
            return FeaturedSellersPage(items: items, total: items.count)
        }
        guard let obj = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            return FeaturedSellersPage(items: [], total: 0)
        }
        let items = parseRows(from: obj)
        let total = pageTotal(from: obj, itemCount: items.count)
        return FeaturedSellersPage(items: items, total: max(total, items.count))
    }

    static func parse(_ raw: String) -> [FeaturedSellerItem] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let json = trimmed.data(using: .utf8) else { return [] }
        if trimmed.hasPrefix("[") {
            let arr = (try? JSONSerialization.jsonObject(with: json) as? [[String: Any]]) ?? []
            return arr.compactMap(parseRow)
        }
        guard let obj = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else { return [] }
        return parseRows(from: obj)
    }

    private static let itemArrayKeys = [
        "items", "Items", "data", "featured_sellers", "featuredSellers", "sellers", "results", "users",
    ]

    private static func parseRows(from obj: [String: Any]) -> [FeaturedSellerItem] {
        resolveItemRows(in: obj).compactMap(parseRow)
    }

    private static func resolveItemRows(in obj: [String: Any]) -> [[String: Any]] {
        for key in itemArrayKeys {
            if let rows = obj[key] as? [[String: Any]] { return rows }
        }
        if let envelope = obj["data"] as? [String: Any] {
            for key in itemArrayKeys where key != "data" {
                if let rows = envelope[key] as? [[String: Any]] { return rows }
            }
        }
        return []
    }

    private static func pageTotal(from obj: [String: Any], itemCount: Int) -> Int {
        if let n = obj["total"] as? NSNumber { return n.intValue }
        if let n = obj["Total"] as? NSNumber { return n.intValue }
        if let envelope = obj["data"] as? [String: Any] {
            if let n = envelope["total"] as? NSNumber { return n.intValue }
            if let n = envelope["Total"] as? NSNumber { return n.intValue }
        }
        return itemCount
    }

    private static func parseRow(_ o: [String: Any]) -> FeaturedSellerItem? {
        let previewKeys = ["preview_listing_ids", "PreviewListingIDs", "previewListingIds"]
        var previewIds: [String] = []
        for key in previewKeys {
            if let ids = o[key] as? [String] {
                previewIds = ids.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                break
            }
        }
        previewIds = Array(previewIds.prefix(3))

        let userId = ["user_id", "UserID", "userId", "userID"]
            .compactMap { o[$0] as? String }
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
            .trimmingCharacters(in: .whitespaces) ?? ""

        let item = FeaturedSellerItem(
            userId: userId,
            username: optString(o, "username", "Username"),
            displayName: optString(o, "display_name", "DisplayName"),
            bio: optString(o, "bio", "Bio"),
            avatarUrl: optString(o, "avatar_url", "AvatarURL"),
            followerCount: optInt(o, "follower_count", "FollowerCount"),
            listingCount: optInt(o, "listing_count", "ListingCount"),
            averageRating: optFloat(o, "average_rating", "AverageRating"),
            verified: optBool(o, "verified", "Verified"),
            previewListingIds: previewIds
        )
        return (item.userId.isEmpty && item.username.isEmpty) ? nil : item
    }

    private static func optString(_ o: [String: Any], _ keys: String...) -> String {
        for key in keys {
            if let s = o[key] as? String {
                let t = s.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty { return t }
            }
        }
        return ""
    }

    private static func optInt(_ o: [String: Any], _ keys: String...) -> Int {
        for key in keys {
            if let n = o[key] as? NSNumber { return n.intValue }
            if let s = o[key] as? String, let n = Int(s) { return n }
        }
        return 0
    }

    private static func optBool(_ o: [String: Any], _ keys: String...) -> Bool {
        for key in keys {
            if let b = o[key] as? Bool { return b }
            if let n = o[key] as? NSNumber { return n.boolValue }
        }
        return false
    }

    private static func optFloat(_ o: [String: Any], _ keys: String...) -> Float? {
        for key in keys {
            if o[key] is NSNull { continue }
            if let n = o[key] as? NSNumber { return n.floatValue }
            if let d = o[key] as? Double { return Float(d) }
        }
        return nil
    }
}
