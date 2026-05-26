import Foundation

/// Enriched listing fields for the Explore/Home quick-look sheet.
struct ListingPreviewDetail: Hashable {
    let title: String
    let description: String?
    let imageURLs: [String]
    let priceVnd: Int64
    let listPriceVnd: Int64?
    let condition: String?
    let size: String?
    let brand: String?
    let category: String?
    let aestheticTag: String?
    let status: String?
    let likeCount: Int
    let saveCount: Int
    let viewCount: Int
    let isLiked: Bool
    let isSaved: Bool
    let sellerDisplayName: String?
    let sellerUsername: String?
    let sellerListingCount: Int?
    let sellerAvatarURL: String?
    let estimatedShippingVnd: Int64?
    let shipFromRegion: String?

    static func parse(_ obj: [String: Any]) -> ListingPreviewDetail? {
        guard let id = (obj["id"] as? String) ?? (obj["listing_id"] as? String) else { return nil }
        _ = id

        let title = obj["title"] as? String ?? obj["name"] as? String ?? ""
        let description = (obj["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        var imageURLs: [String] = []
        if let urls = obj["image_urls"] as? [String] {
            imageURLs = urls
        } else if let images = obj["images"] as? [[String: Any]] {
            imageURLs = images.compactMap { $0["url"] as? String }
        } else if let thumb = obj["thumbnail_url"] as? String {
            imageURLs = [thumb]
        }

        let priceVnd = (obj["price"] as? NSNumber)?.int64Value ?? 0
        let listPriceVnd = (obj["list_price"] as? NSNumber)?.int64Value
            ?? (obj["original_price"] as? NSNumber)?.int64Value

        let condition = obj["condition"] as? String
        let size = obj["size"] as? String
        let brand = (obj["brand"] as? [String: Any])?["name"] as? String ?? obj["brand"] as? String
        let category = (obj["category"] as? [String: Any])?["name"] as? String ?? obj["category"] as? String

        var aestheticTag: String?
        if let tags = obj["aesthetic_tags"] as? [[String: Any]], let first = tags.first {
            aestheticTag = (first["display_name"] as? String) ?? (first["name"] as? String)
        } else if let tags = obj["aesthetic_tags"] as? [String], let first = tags.first {
            aestheticTag = first
        }

        let status = obj["status"] as? String
        let likeCount = (obj["like_count"] as? NSNumber)?.intValue ?? 0
        let saveCount = (obj["save_count"] as? NSNumber)?.intValue ?? 0
        let viewCount = (obj["view_count"] as? NSNumber)?.intValue ?? 0
        let isLiked = obj["is_liked"] as? Bool ?? false
        let isSaved = obj["is_saved"] as? Bool ?? false

        let seller = obj["seller"] as? [String: Any]
        let sellerDisplayName = seller?["display_name"] as? String ?? seller?["name"] as? String
        let sellerUsername = seller?["username"] as? String
        let sellerListingCount = (seller?["listing_count"] as? NSNumber)?.intValue
        let sellerAvatarURL = seller?["avatar_url"] as? String ?? seller?["profile_image_url"] as? String

        let estimatedShippingVnd = (obj["estimated_shipping_fee"] as? NSNumber)?.int64Value
            ?? (obj["shipping_fee"] as? NSNumber)?.int64Value

        var shipFromRegion: String?
        if let addr = obj["shipping_address"] as? [String: Any] {
            shipFromRegion = (addr["city"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? (addr["region"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if shipFromRegion?.isEmpty != false {
            shipFromRegion = (obj["country_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ListingPreviewDetail(
            title: title,
            description: description,
            imageURLs: imageURLs,
            priceVnd: priceVnd,
            listPriceVnd: listPriceVnd,
            condition: condition,
            size: size,
            brand: brand,
            category: category,
            aestheticTag: aestheticTag,
            status: status,
            likeCount: likeCount,
            saveCount: saveCount,
            viewCount: viewCount,
            isLiked: isLiked,
            isSaved: isSaved,
            sellerDisplayName: sellerDisplayName,
            sellerUsername: sellerUsername,
            sellerListingCount: sellerListingCount,
            sellerAvatarURL: sellerAvatarURL,
            estimatedShippingVnd: estimatedShippingVnd,
            shipFromRegion: shipFromRegion?.isEmpty == false ? shipFromRegion : nil
        )
    }
}
