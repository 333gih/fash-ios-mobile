import Foundation
import UIKit

/// Port of Android `FeedImageUrl` (ui.feed).
enum FeedImageUrl {
    static func resolveListingImageUrl(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.lowercased().hasPrefix("http") { return trimmed }
        let base = AppEnvironment.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.hasPrefix("/") { return "\(base)\(trimmed)" }
        return "\(base)/\(trimmed)"
    }

    static func resolveProfileImageUrl(_ path: String) -> String {
        resolveListingImageUrl(path)
    }

    static func resolveProfileImageUrlOrNil(_ path: String?) -> String? {
        guard let path = path?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else { return nil }
        let resolved = resolveListingImageUrl(path)
        return resolved.isEmpty ? nil : resolved
    }

    static func resolveListingImageUrlOrNil(_ path: String?) -> String? {
        resolveProfileImageUrlOrNil(path)
    }
}

/// Feed grid image sizing — downsampled decode + Shopify `width` param (Pinterest-style loading).
enum FeedListingImageSizer {
    private static let minFeedWidthPx = 320
    private static let maxFeedWidthPx = 800

    static func pixelSize(columnWidthPoints: CGFloat, aspectRatio: CGFloat, scale: CGFloat = UIScreen.main.nativeScale) -> CGSize {
        let w = min(maxFeedWidthPx, max(minFeedWidthPx, Int(columnWidthPoints * scale)))
        let h = max(1, Int(CGFloat(w) / max(0.01, aspectRatio)))
        return CGSize(width: w, height: h)
    }

    /// Resolved absolute URL tuned for a masonry tile (not for product detail full-bleed).
    static func urlForFeedGrid(_ path: String, columnWidthPoints: CGFloat, aspectRatio: CGFloat) -> String {
        let resolved = FeedImageUrl.resolveListingImageUrl(path)
        guard !resolved.isEmpty else { return "" }
        let targetW = min(maxFeedWidthPx, max(minFeedWidthPx, Int(columnWidthPoints * UIScreen.main.nativeScale)))
        return applyShopifyWidthQuery(resolved, widthPx: targetW)
    }

    private static func applyShopifyWidthQuery(_ url: String, widthPx: Int) -> String {
        guard let host = URL(string: url)?.host?.lowercased(),
              host.contains("shopify") || host.contains("cdn.shopify")
        else { return url }
        guard var components = URLComponents(string: url) else { return url }
        var items = components.queryItems ?? []
        items.removeAll { $0.name.lowercased() == "width" }
        items.append(URLQueryItem(name: "width", value: String(widthPx)))
        components.queryItems = items
        return components.string ?? url
    }
}
