import Foundation
import Kingfisher
import UIKit

/// Warms the image cache after feed JSON arrives so masonry tiles paint without visible loading.
enum FeedListingImagePrefetch {
    private static let maxItems = 28

    static func defaultColumnWidthPoints() -> CGFloat {
        let screen = UIScreen.main.bounds.width
        return max(120, (screen - 24) / 2)
    }

    static func prefetch(items: [ListingFeedItem], columnWidthPoints: CGFloat? = nil) {
        let colW = columnWidthPoints ?? defaultColumnWidthPoints()
        let scale = UIScreen.main.scale

        // Prefetch using per-item KingfisherManager calls (not ImagePrefetcher) so each
        // request gets the correct per-item DownsamplingImageProcessor size.
        // Cache key: Kingfisher defaults to url.absoluteString — this matches exactly what
        // KFImage uses at display time (no custom cacheKey), so prefetched images are found.
        for item in items.prefix(maxItems) {
            let raw = item.coverImageUrl.trimmingCharacters(in: .whitespaces)
            let path = raw.isEmpty ? (item.imageUrls.first ?? "") : raw
            guard !path.isEmpty else { continue }
            let ratio = ListingMasonryGrid.masonryAspectRatio(for: item)
            let feedUrl = FeedListingImageSizer.urlForFeedGrid(
                path,
                columnWidthPoints: colW,
                aspectRatio: ratio
            )
            guard !feedUrl.isEmpty, let url = URL(string: feedUrl) else { continue }
            let px = FeedListingImageSizer.pixelSize(
                columnWidthPoints: colW,
                aspectRatio: ratio,
                scale: scale
            )
            let options: KingfisherOptionsInfo = [
                .processor(DownsamplingImageProcessor(size: px)),
                .scaleFactor(scale),
                .backgroundDecode
            ]
            KingfisherManager.shared.retrieveImage(with: url, options: options, completionHandler: nil)
        }
    }
}
