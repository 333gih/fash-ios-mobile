import Foundation

/// Port of Android `ListingImageUrlsWire` — step objects in `image_urls` + cover derivation.
enum ListingImageUrlsWire {
    private struct Row {
        let sortOrder: Int
        let index: Int
        let url: String
    }

    static func parseUrlStrings(from listing: [String: Any]) -> [String] {
        guard let arr = imageUrlsNode(from: listing) else { return [] }
        var rows: [Row] = []
        for (index, element) in arr.enumerated() {
            if let o = element as? [String: Any] {
                let url = RepositoryHttp.optString(o, "image_url", "ImageURL").trimmingCharacters(in: .whitespaces)
                guard !url.isEmpty else { continue }
                var order = index
                if o["sort_order"] != nil || o["SortOrder"] != nil {
                    order = RepositoryHttp.optInt(o, "sort_order", "SortOrder", default: index)
                }
                rows.append(Row(sortOrder: order, index: index, url: url))
            } else if let s = element as? String {
                let trimmed = s.trimmingCharacters(in: .whitespaces)
                let looksLikeJson = trimmed.first.map { $0 == Character(UnicodeScalar(0x7B)!) } ?? false
                if !trimmed.isEmpty, !looksLikeJson {
                    rows.append(Row(sortOrder: index, index: index, url: trimmed))
                }
            }
        }
        return rows
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.index < rhs.index
            }
            .map(\.url)
    }

    static func resolveCoverUrl(coverFromRoot: String, listing: [String: Any]) -> String {
        let root = coverFromRoot.trimmingCharacters(in: .whitespaces)
        if !root.isEmpty { return root }
        return parseUrlStrings(from: listing).first ?? ""
    }

    private static func imageUrlsNode(from listing: [String: Any]) -> [Any]? {
        if let arr = listing["image_urls"] as? [Any] { return arr }
        if let arr = listing["ImageURLs"] as? [Any] { return arr }
        if let images = listing["images"] as? [[String: Any]] {
            return images
        }
        if let thumb = listing["thumbnail_url"] as? String, !thumb.isEmpty {
            return [thumb]
        }
        return nil
    }
}
