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

        guard let components = URLComponents(string: resolved),
              let host = components.host?.lowercased() else { return resolved }

        // Shopify CDN: use native ?width= resize param
        if host.contains("shopify") {
            return applyShopifyWidthQuery(resolved, components: components, widthPx: targetW)
        }

        // Self-hosted SeaweedFS: route through imgproxy for on-the-fly WebP thumbnail.
        // Path always starts with /fash-uploads/ (bucket name embedded in URL path).
        let resizeBase = AppEnvironment.imageResizeBaseURL
        if !resizeBase.isEmpty, components.path.hasPrefix("/fash-uploads/") {
            // /fash-uploads/listings/... → s3://fash-uploads/listings/...
            let s3Source = "s3:" + components.path
            guard let encoded = s3Source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return resolved
            }
            return "\(resizeBase)/unsafe/rs:fit:\(targetW):0:0/plain/\(encoded)"
        }

        return resolved
    }

    private static func applyShopifyWidthQuery(_ url: String, components: URLComponents, widthPx: Int) -> String {
        var comp = components
        var items = comp.queryItems ?? []
        items.removeAll { $0.name.lowercased() == "width" }
        items.append(URLQueryItem(name: "width", value: String(widthPx)))
        comp.queryItems = items
        return comp.string ?? url
    }
}
