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
        
        let resources: [ImageResource] = items.prefix(maxItems).compactMap { item -> ImageResource? in
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
            
            // Match the cache key used by FashAsyncImage display
            let pixelSize = FeedListingImageSizer.pixelSize(
                columnWidthPoints: colW,
                aspectRatio: ratio,
                scale: scale
            )
            let cacheKey = "feed_\(item.id)_\(Int(colW))_\(Int(pixelSize.width))x\(Int(pixelSize.height))"
            
            return ImageResource(downloadURL: url, cacheKey: cacheKey)
        }
        
        guard !resources.isEmpty else { return }
        
        // Use the same processor and options as FashAsyncImage
        let targetSize = FeedListingImageSizer.pixelSize(
            columnWidthPoints: colW,
            aspectRatio: 1.0, // Average aspect ratio for processor init
            scale: scale
        )
        
        ImagePrefetcher(
            resources: resources,
            options: [
                .processor(DownsamplingImageProcessor(size: targetSize)),
                .scaleFactor(scale),
                .cacheOriginalImage
            ]
        ).start()
    }
}
