import Foundation

struct ListingFeedItem: Identifiable, Hashable {
    let id: String
    let title: String
    let price: Int64
    let imageURL: String?
    let sellerUsername: String?
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
        guard let id = (row["id"] as? String) ?? (row["listing_id"] as? String) else { return nil }
        let title = row["title"] as? String ?? row["name"] as? String ?? ""
        let price = (row["price"] as? NSNumber)?.int64Value ?? 0
        let imageURL = firstImageURL(from: row)
        let seller = (row["seller"] as? [String: Any])?["username"] as? String
        return ListingFeedItem(id: id, title: title, price: price, imageURL: imageURL, sellerUsername: seller)
    }

    private static func firstImageURL(from row: [String: Any]) -> String? {
        if let url = row["thumbnail_url"] as? String { return url }
        if let urls = row["image_urls"] as? [String], let first = urls.first { return first }
        if let images = row["images"] as? [[String: Any]] {
            return images.compactMap { $0["url"] as? String }.first
        }
        return nil
    }
}
