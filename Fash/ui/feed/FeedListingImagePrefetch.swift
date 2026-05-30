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
        let urls: [URL] = items.prefix(maxItems).compactMap { item -> URL? in
            let raw = item.coverImageUrl.trimmingCharacters(in: .whitespaces)
            let path = raw.isEmpty ? (item.imageUrls.first ?? "") : raw
            guard !path.isEmpty else { return nil }
            let ratio = ListingMasonryGrid.masonryAspectRatio(for: item)
            let feedUrl = FeedListingImageSizer.urlForFeedGrid(
                path,
                columnWidthPoints: colW,
                aspectRatio: ratio
            )
            guard !feedUrl.isEmpty, let url = URL(string: feedUrl) else { return nil }
            return url
        }
        guard !urls.isEmpty else { return }
        let px = FeedListingImageSizer.pixelSize(
            columnWidthPoints: colW,
            aspectRatio: 4 / 3
        )
        let processor = DownsamplingImageProcessor(size: px)
        ImagePrefetcher(urls: urls, options: [.processor(processor)]).start()
    }
}
