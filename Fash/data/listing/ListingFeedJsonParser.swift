import Foundation

struct ListingFeedItem: Identifiable, Hashable {
    let id: String
    let title: String
    let coverImageUrl: String
    let imageUrls: [String]
    let priceVnd: Int64
    let brand: String?
    let size: String?
    let categoryName: String?
    let listingAestheticTag: String?
    let condition: String
    let likeCount: Int
    let saveCount: Int
    let sellerId: String?
    let sellerUsername: String?
    let sellerStyleTag: String?
    let createdAt: String?
    let isLiked: Bool
    let isSaved: Bool
    let onsiteInspectionCommitment: Bool
    let listingStatus: String?
    let descriptionText: String

    /// Legacy aliases
    var price: Int64 { priceVnd }
    var imageURL: String? { coverImageUrl.isEmpty ? nil : coverImageUrl }

    init(
        id: String,
        title: String,
        coverImageUrl: String = "",
        imageUrls: [String] = [],
        priceVnd: Int64 = 0,
        brand: String? = nil,
        size: String? = nil,
        categoryName: String? = nil,
        listingAestheticTag: String? = nil,
        condition: String = "",
        likeCount: Int = 0,
        saveCount: Int = 0,
        sellerId: String? = nil,
        sellerUsername: String? = nil,
        sellerStyleTag: String? = nil,
        createdAt: String? = nil,
        isLiked: Bool = false,
        isSaved: Bool = false,
        onsiteInspectionCommitment: Bool = false,
        listingStatus: String? = nil,
        descriptionText: String = ""
    ) {
        self.id = id
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.imageUrls = imageUrls
        self.priceVnd = priceVnd
        self.brand = brand
        self.size = size
        self.categoryName = categoryName
        self.listingAestheticTag = listingAestheticTag
        self.condition = condition
        self.likeCount = likeCount
        self.saveCount = saveCount
        self.sellerId = sellerId
        self.sellerUsername = sellerUsername
        self.sellerStyleTag = sellerStyleTag
        self.createdAt = createdAt
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.onsiteInspectionCommitment = onsiteInspectionCommitment
        self.listingStatus = listingStatus
        self.descriptionText = descriptionText
    }

    /// Convenience for legacy call sites
    init(id: String, title: String, price: Int64, imageURL: String?, sellerUsername: String?) {
        self.init(
            id: id,
            title: title,
            coverImageUrl: imageURL ?? "",
            imageUrls: imageURL.map { [$0] } ?? [],
            priceVnd: price,
            sellerUsername: sellerUsername
        )
    }
}

enum ListingFeedJsonParser {
    static func parseFeed(_ data: Data) throws -> [ListingFeedItem] {
        let root = try JSONSerialization.jsonObject(with: data)
        let rows: [[String: Any]]
        if let arr = root as? [[String: Any]] {
            rows = arr
        } else if let obj = root as? [String: Any], let items = obj["items"] as? [[String: Any]] {
            rows = items
        } else if let obj = root as? [String: Any], let dataArr = obj["data"] as? [[String: Any]] {
            rows = dataArr
        } else {
            rows = []
        }
        return rows.compactMap(parseRow)
    }

    private static func parseRow(_ row: [String: Any]) -> ListingFeedItem? {
        guard let id = (row["id"] as? String) ?? (row["ID"] as? String) ?? (row["listing_id"] as? String) else { return nil }
        let title = (row["title"] as? String) ?? (row["Title"] as? String) ?? (row["name"] as? String) ?? ""
        let priceVnd = (row["price"] as? NSNumber)?.int64Value ?? (row["Price"] as? NSNumber)?.int64Value ?? 0
        let imageUrls = parseImageUrls(from: row)
        let cover = (row["cover_image_url"] as? String) ?? (row["CoverImageURL"] as? String) ?? imageUrls.first ?? ""
        let seller = (row["seller"] as? [String: Any]) ?? (row["Seller"] as? [String: Any])
        let sellerUsername = seller?["username"] as? String ?? seller?["Username"] as? String
        let sellerId = seller?["user_id"] as? String ?? seller?["UserID"] as? String ?? row["seller_id"] as? String
        let categoryObj = (row["category"] as? [String: Any]) ?? (row["Category"] as? [String: Any])
        let categoryName = categoryObj?["name"] as? String ?? categoryObj?["Name"] as? String ?? row["category_name"] as? String
        let aestheticArr = row["aesthetic_tags"] as? [[String: Any]] ?? row["AestheticTags"] as? [[String: Any]]
        let listingAesthetic = aestheticArr?.first.flatMap { tag -> String? in
            let name = (tag["display_name"] as? String) ?? (tag["DisplayName"] as? String) ?? (tag["name"] as? String) ?? (tag["Name"] as? String) ?? ""
            return name.isEmpty ? nil : name
        }
        let sellerTags = seller?["aesthetic_tags"] as? [[String: Any]] ?? seller?["AestheticTags"] as? [[String: Any]]
        let sellerStyle = sellerTags?.first.flatMap { tag -> String? in
            let name = (tag["name"] as? String) ?? (tag["display_name"] as? String) ?? (tag["Name"] as? String) ?? ""
            return name.isEmpty ? nil : name
        }
        return ListingFeedItem(
            id: id,
            title: title,
            coverImageUrl: cover,
            imageUrls: imageUrls,
            priceVnd: priceVnd,
            brand: (row["brand"] as? String) ?? (row["Brand"] as? String) ?? ((row["brand"] as? [String: Any])?["name"] as? String),
            size: (row["size"] as? String) ?? (row["Size"] as? String),
            categoryName: categoryName,
            listingAestheticTag: listingAesthetic,
            condition: (row["condition"] as? String) ?? (row["Condition"] as? String) ?? "",
            likeCount: (row["like_count"] as? NSNumber)?.intValue ?? (row["LikeCount"] as? NSNumber)?.intValue ?? 0,
            saveCount: (row["save_count"] as? NSNumber)?.intValue ?? (row["SaveCount"] as? NSNumber)?.intValue ?? 0,
            sellerId: sellerId,
            sellerUsername: sellerUsername,
            sellerStyleTag: sellerStyle,
            createdAt: (row["created_at"] as? String) ?? (row["CreatedAt"] as? String),
            isLiked: (row["is_liked"] as? Bool) ?? (row["IsLiked"] as? Bool) ?? false,
            isSaved: (row["is_saved"] as? Bool) ?? (row["IsSaved"] as? Bool) ?? false,
            onsiteInspectionCommitment: (row["onsite_inspection_commitment"] as? Bool) ?? (row["OnsiteInspectionCommitment"] as? Bool) ?? false,
            listingStatus: ((row["status"] as? String) ?? (row["Status"] as? String) ?? (row["listing_status"] as? String))?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            descriptionText: (row["description"] as? String) ?? (row["Description"] as? String) ?? ""
        )
    }

    private static func parseImageUrls(from row: [String: Any]) -> [String] {
        if let urls = row["image_urls"] as? [String] { return urls }
        if let urls = row["ImageURLs"] as? [String] { return urls }
        if let images = row["images"] as? [[String: Any]] {
            return images.compactMap { $0["url"] as? String }
        }
        if let url = row["thumbnail_url"] as? String { return [url] }
        return []
    }
}
