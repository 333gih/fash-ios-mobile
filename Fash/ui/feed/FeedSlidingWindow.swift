import Foundation

/// Cursor-paginated home feed page — backend `HomeFeedPageResponse`.
struct HomeFeedPage: Sendable {
    let items: [ListingFeedItem]
    let hasMore: Bool
    let nextCursor: String?
}

/// TikTok-style bounded in-memory window with front-trim + scroll compensation.
struct FeedSlidingWindow {
    private(set) var items: [ListingFeedItem] = []
    /// Logical index of `items[0]` in the full feed timeline (for analytics).
    private(set) var logicalStartIndex = 0

    struct Config {
        static let maxItems = 80
        static let bufferBefore = 30
        static let bufferAfter = 30
        static let prefetchThreshold = 10
    }

    struct TrimResult {
        let removedCount: Int
        let scrollDeltaY: CGFloat
    }

    mutating func reset(with initial: [ListingFeedItem]) {
        items = initial
        logicalStartIndex = 0
    }

    /// Append-only with dedupe — never replaces the whole array.
    mutating func appendUnique(_ newItems: [ListingFeedItem], knownIds: inout Set<String>) -> Int {
        let fresh = newItems.filter { knownIds.insert($0.id).inserted }
        guard !fresh.isEmpty else { return 0 }
        items.append(contentsOf: fresh)
        return fresh.count
    }

    /// Drop rows far above the viewport; returns estimated scroll adjustment for UIKit.
    mutating func trimFrontIfNeeded(visibleIndex: Int, columnWidth: CGFloat) -> TrimResult? {
        guard items.count > Config.maxItems else { return nil }
        guard visibleIndex >= Config.bufferBefore + 8 else { return nil }

        let targetStart = max(0, visibleIndex - Config.bufferBefore)
        let removeCount = min(targetStart, items.count - Config.maxItems / 2)
        guard removeCount > 0 else { return nil }

        let removed = Array(items.prefix(removeCount))
        let deltaY = Self.estimateTrimmedHeight(items: removed, columnWidth: columnWidth)
        items.removeFirst(removeCount)
        logicalStartIndex += removeCount
        return TrimResult(removedCount: removeCount, scrollDeltaY: deltaY)
    }

    mutating func mapItems(_ transform: (ListingFeedItem) -> ListingFeedItem) {
        items = items.map(transform)
    }

    private static func estimateTrimmedHeight(items: [ListingFeedItem], columnWidth: CGFloat) -> CGFloat {
        guard !items.isEmpty, columnWidth > 1 else { return 0 }
        let gap: CGFloat = 8
        var left: CGFloat = 0
        var right: CGFloat = 0
        for (idx, item) in items.enumerated() {
            let h = ListingMasonryGrid.tileHeight(columnWidth: columnWidth, item: item)
            if idx.isMultiple(of: 2) {
                left += h + gap
            } else {
                right += h + gap
            }
        }
        return max(left, right)
    }
}
