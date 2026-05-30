import Foundation

/// Port of Android `ListingImageUrlsWire` — step objects in `image_urls` + cover derivation.
enum ListingImageUrlsWire {
    private struct ImageStepRow {
        let sortOrder: Int
        let index: Int
        let url: String
        let width: Int?
        let height: Int?
    }

    struct CoverImageMeta {
        let url: String
        let width: Int?
        let height: Int?
    }

    static func parseUrlStrings(from listing: [String: Any]) -> [String] {
        parseImageSteps(from: listing).map(\.url)
    }

    static func resolveCoverUrl(coverFromRoot: String, listing: [String: Any]) -> String {
        resolveCoverMeta(coverFromRoot: coverFromRoot, listing: listing).url
    }

    /// Cover URL plus pixel dimensions from the matching `image_urls` step when the API sends them.
    static func resolveCoverMeta(coverFromRoot: String, listing: [String: Any]) -> CoverImageMeta {
        let root = coverFromRoot.trimmingCharacters(in: .whitespaces)
        let steps = parseImageSteps(from: listing)
        if !root.isEmpty {
            let match = steps.first { imageUrlsReferToSameAsset($0.url, root) }
            if let match {
                return CoverImageMeta(url: root, width: match.width, height: match.height)
            }
            // Signed CDN URLs often differ from stored step paths — reuse first step dimensions.
            if let first = steps.first, first.width != nil, first.height != nil {
                return CoverImageMeta(url: root, width: first.width, height: first.height)
            }
            return CoverImageMeta(url: root, width: nil, height: nil)
        }
        if let first = steps.first {
            return CoverImageMeta(url: first.url, width: first.width, height: first.height)
        }
        return CoverImageMeta(url: "", width: nil, height: nil)
    }

    /// Same asset when paths match ignoring query (Shopify/CDN signing).
    private static func imageUrlsReferToSameAsset(_ lhs: String, _ rhs: String) -> Bool {
        let a = normalizeImageUrlPath(lhs)
        let b = normalizeImageUrlPath(rhs)
        if a.isEmpty || b.isEmpty { return false }
        if a == b { return true }
        return a.hasSuffix(b) || b.hasSuffix(a)
    }

    private static func normalizeImageUrlPath(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return trimmed }
        components.query = nil
        components.fragment = nil
        return components.string ?? trimmed
    }

    private static func parseImageSteps(from listing: [String: Any]) -> [ImageStepRow] {
        guard let arr = imageUrlsNode(from: listing) else { return [] }
        var rows: [ImageStepRow] = []
        for (index, element) in arr.enumerated() {
            if let o = element as? [String: Any] {
                let url = RepositoryHttp.optString(o, "image_url", "ImageURL").trimmingCharacters(in: .whitespaces)
                guard !url.isEmpty else { continue }
                var order = index
                if o["sort_order"] != nil || o["SortOrder"] != nil {
                    order = RepositoryHttp.optInt(o, "sort_order", "SortOrder", default: index)
                }
                let width = positiveDimension(o, "width", "Width")
                let height = positiveDimension(o, "height", "Height")
                rows.append(ImageStepRow(sortOrder: order, index: index, url: url, width: width, height: height))
            } else if let s = element as? String {
                let trimmed = s.trimmingCharacters(in: .whitespaces)
                let looksLikeJson = trimmed.first.map { $0 == Character(UnicodeScalar(0x7B)!) } ?? false
                if !trimmed.isEmpty, !looksLikeJson {
                    rows.append(ImageStepRow(sortOrder: index, index: index, url: trimmed, width: nil, height: nil))
                }
            }
        }
        return rows.sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
            return lhs.index < rhs.index
        }
    }

    private static func positiveDimension(_ o: [String: Any], _ snake: String, _ pascal: String) -> Int? {
        let v = RepositoryHttp.optInt(o, snake, pascal, default: 0)
        return v > 0 ? v : nil
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
