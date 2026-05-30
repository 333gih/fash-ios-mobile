import Foundation

struct ListingFeedItem: Identifiable, Hashable {
    let id: String
    let title: String
    let coverImageUrl: String
    let coverImageWidth: Int?
    let coverImageHeight: Int?
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
        coverImageWidth: Int? = nil,
        coverImageHeight: Int? = nil,
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
        self.coverImageWidth = coverImageWidth
        self.coverImageHeight = coverImageHeight
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

extension ListingFeedItem {
    /// Optimistic UI before the API returns.
    var toggledLike: ListingFeedItem { applyingLikeToggle(!isLiked) }

    /// Optimistic UI before the API returns.
    var toggledSave: ListingFeedItem { applyingSaveToggle(!isSaved) }

    /// Stable masonry column assignment; changes when like/save toggles so cells refresh.
    var masonryCellId: String { "\(id)#\(isLiked)#\(isSaved)" }

    func applyingLikeToggle(_ liked: Bool) -> ListingFeedItem {
        let delta = (liked && !isLiked) ? 1 : ((!liked && isLiked) ? -1 : 0)
        return withEngagement(
            likeCount: max(0, likeCount + delta),
            isLiked: liked,
            saveCount: saveCount,
            isSaved: isSaved
        )
    }

    func applyingSaveToggle(_ saved: Bool) -> ListingFeedItem {
        let delta = (saved && !isSaved) ? 1 : ((!saved && isSaved) ? -1 : 0)
        return withEngagement(
            likeCount: likeCount,
            isLiked: isLiked,
            saveCount: max(0, saveCount + delta),
            isSaved: saved
        )
    }

    func withEngagement(likeCount: Int, isLiked: Bool, saveCount: Int, isSaved: Bool) -> ListingFeedItem {
        ListingFeedItem(
            id: id,
            title: title,
            coverImageUrl: coverImageUrl,
            coverImageWidth: coverImageWidth,
            coverImageHeight: coverImageHeight,
            imageUrls: imageUrls,
            priceVnd: priceVnd,
            brand: brand,
            size: size,
            categoryName: categoryName,
            listingAestheticTag: listingAestheticTag,
            condition: condition,
            likeCount: likeCount,
            saveCount: saveCount,
            sellerId: sellerId,
            sellerUsername: sellerUsername,
            sellerStyleTag: sellerStyleTag,
            createdAt: createdAt,
            isLiked: isLiked,
            isSaved: isSaved,
            onsiteInspectionCommitment: onsiteInspectionCommitment,
            listingStatus: listingStatus,
            descriptionText: descriptionText
        )
    }
}

enum ListingFeedJsonParser {
    /// Home recommendation section arrays — Android `parseItemsArray`.
    static func parseItemsArray(_ arr: [[String: Any]]?) -> [ListingFeedItem] {
        guard let arr else { return [] }
        return arr.compactMap(parseRow)
    }

    static func parseFeed(_ data: Data) throws -> [ListingFeedItem] {
        let root = try JSONSerialization.jsonObject(with: data)
        return extractListingRows(from: root).compactMap(parseRow)
    }

    /// Wishlist, seller listings, search — Android [extractListingsArray] / [parseFeedArray].
    private static func extractListingRows(from root: Any) -> [[String: Any]] {
        if let arr = root as? [[String: Any]] { return arr }
        guard let obj = root as? [String: Any] else { return [] }
        if let data = obj["data"] {
            if let arr = data as? [[String: Any]] { return arr }
            if let nested = data as? [String: Any] { return listingRows(in: nested) }
        }
        if let listing = obj["listing"] as? [String: Any] { return [listing] }
        return listingRows(in: obj)
    }

    private static func listingRows(in obj: [String: Any]) -> [[String: Any]] {
        for key in ["listings", "Listings", "items", "Items", "results", "Results", "rows", "Rows"] {
            if obj[key] != nil {
                return (obj[key] as? [[String: Any]]) ?? []
            }
        }
        if obj["id"] != nil || obj["ID"] != nil || obj["listing_id"] != nil {
            return [obj]
        }
        return []
    }

    /// Single listing from `GET /listings/{id}` (object or `{ data: {...} }`).
    static func parseListingDetail(_ data: Data) throws -> ListingFeedItem? {
        let items = try parseFeed(data)
        if let first = items.first { return first }
        let root = try JSONSerialization.jsonObject(with: data)
        guard let obj = root as? [String: Any] else { return nil }
        if let nested = obj["data"] as? [String: Any], let item = parseRow(nested) { return item }
        if let listing = obj["listing"] as? [String: Any], let item = parseRow(listing) { return item }
        return parseRow(obj)
    }

    static func parseRow(_ row: [String: Any]) -> ListingFeedItem? {
        guard let id = (row["id"] as? String) ?? (row["ID"] as? String) ?? (row["listing_id"] as? String) else { return nil }
        let title = (row["title"] as? String) ?? (row["Title"] as? String) ?? (row["name"] as? String) ?? ""
        let priceVnd = (row["price"] as? NSNumber)?.int64Value ?? (row["Price"] as? NSNumber)?.int64Value ?? 0
        let coverRoot = RepositoryHttp.optString(row, "cover_image_url", "CoverImageURL")
        let coverMeta = ListingImageUrlsWire.resolveCoverMeta(coverFromRoot: coverRoot, listing: row)
        let imageUrls = ListingImageUrlsWire.parseUrlStrings(from: row)
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
        let rootCoverW = RepositoryHttp.optInt(
            row,
            "cover_image_width", "CoverImageWidth", "image_width", "imageWidth",
            default: 0
        )
        let rootCoverH = RepositoryHttp.optInt(
            row,
            "cover_image_height", "CoverImageHeight", "image_height", "imageHeight",
            default: 0
        )
        let coverW = rootCoverW > 0 ? rootCoverW : coverMeta.width
        let coverH = rootCoverH > 0 ? rootCoverH : coverMeta.height
        return ListingFeedItem(
            id: id,
            title: title,
            coverImageUrl: coverMeta.url,
            coverImageWidth: coverW,
            coverImageHeight: coverH,
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

}
