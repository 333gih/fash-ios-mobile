import Foundation
import SwiftUI
import UIKit

/// Cursor-paginated home feed page — backend `HomeFeedPageResponse`.
struct HomeFeedPage: Sendable {
    let items: [ListingFeedItem]
    let hasMore: Bool
    let nextCursor: String?
}

/// Window sizing — home following vs image-heavy seller storefront.
struct FeedSlidingWindowPolicy: Sendable {
    var maxItems: Int
    var bufferBefore: Int
    var bufferAfter: Int
    var backfillVisibleThreshold: Int

    static let homeFollowing = FeedSlidingWindowPolicy(
        maxItems: 80,
        bufferBefore: 30,
        bufferAfter: 30,
        backfillVisibleThreshold: 12
    )

    /// Tighter cap — seller grids load full-bleed photos; trim earlier to avoid jetsam.
    static let sellerStorefront = FeedSlidingWindowPolicy(
        maxItems: 48,
        bufferBefore: 16,
        bufferAfter: 16,
        backfillVisibleThreshold: 10
    )
}

/// TikTok-style bounded in-memory window with front-trim + scroll compensation.
struct FeedSlidingWindow {
    private(set) var items: [ListingFeedItem] = []
    /// Logical index of `items[0]` in the full feed timeline (for analytics / offset backfill).
    private(set) var logicalStartIndex = 0

    struct Config {
        static let maxItems = FeedSlidingWindowPolicy.homeFollowing.maxItems
        static let bufferBefore = FeedSlidingWindowPolicy.homeFollowing.bufferBefore
        static let bufferAfter = FeedSlidingWindowPolicy.homeFollowing.bufferAfter
        static let prefetchThreshold = 10
    }

    struct TrimResult {
        let removedCount: Int
        /// Positive height removed from top — subtract from `contentOffset.y`.
        let scrollDeltaY: CGFloat
    }

    struct PrependResult {
        let addedCount: Int
        /// Positive height inserted at top — add to `contentOffset.y`.
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

    /// Rehydrate rows above the window when the user scrolls back toward the header.
    mutating func prependUnique(
        _ newItems: [ListingFeedItem],
        knownIds: inout Set<String>,
        columnWidth: CGFloat
    ) -> PrependResult? {
        let fresh = newItems.filter { knownIds.insert($0.id).inserted }
        guard !fresh.isEmpty else { return nil }
        items.insert(contentsOf: fresh, at: 0)
        logicalStartIndex = max(0, logicalStartIndex - fresh.count)
        let deltaY = Self.estimateMasonryHeight(items: fresh, columnWidth: columnWidth)
        return PrependResult(addedCount: fresh.count, scrollDeltaY: deltaY)
    }

    /// Drop rows far above the viewport; returns estimated scroll adjustment for UIKit.
    mutating func trimFrontIfNeeded(
        visibleIndex: Int,
        columnWidth: CGFloat,
        policy: FeedSlidingWindowPolicy = .homeFollowing
    ) -> TrimResult? {
        guard items.count > policy.maxItems else { return nil }
        guard visibleIndex >= policy.bufferBefore + 6 else { return nil }

        let targetStart = max(0, visibleIndex - policy.bufferBefore)
        let removeCount = min(targetStart, items.count - policy.maxItems / 2)
        guard removeCount > 0 else { return nil }

        let removed = Array(items.prefix(removeCount))
        let deltaY = Self.estimateMasonryHeight(items: removed, columnWidth: columnWidth)
        items.removeFirst(removeCount)
        logicalStartIndex += removeCount
        return TrimResult(removedCount: removeCount, scrollDeltaY: deltaY)
    }

    mutating func mapItems(_ transform: (ListingFeedItem) -> ListingFeedItem) {
        items = items.map(transform)
    }

    /// Engagement / edit — drop rows without shifting [logicalStartIndex].
    mutating func removeItems(withIds ids: Set<String>, knownIds: inout Set<String>) {
        guard !ids.isEmpty else { return }
        items.removeAll { ids.contains($0.id) }
        knownIds.subtract(ids)
    }

    @discardableResult
    mutating func insertUniqueAtTop(_ item: ListingFeedItem, knownIds: inout Set<String>) -> Bool {
        guard knownIds.insert(item.id).inserted else { return false }
        items.insert(item, at: 0)
        return true
    }

    static func estimateMasonryHeight(items: [ListingFeedItem], columnWidth: CGFloat) -> CGFloat {
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

/// Keeps the viewport stable after sliding-window trim/prepend on a parent `ScrollView`.
struct FeedScrollTrimCompensator: UIViewRepresentable {
    var token: Int
    /// Signed UIKit adjustment: negative = trim (scroll up), positive = prepend (scroll down).
    var signedDeltaY: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        uiView.coordinator = context.coordinator
        guard token > 0, token != context.coordinator.lastToken else { return }
        context.coordinator.lastToken = token
        uiView.applyCompensation(signedDeltaY: signedDeltaY)
    }

    final class Coordinator {
        var lastToken = 0
    }

    final class AnchorView: UIView {
        weak var coordinator: Coordinator?

        func applyCompensation(signedDeltaY: CGFloat) {
            DispatchQueue.main.async { [weak self] in
                self?.applyCompensationNow(signedDeltaY: signedDeltaY)
            }
        }

        private func applyCompensationNow(signedDeltaY: CGFloat) {
            guard abs(signedDeltaY) > 0.5, let scrollView = enclosingScrollView() else { return }
            scrollView.layoutIfNeeded()
            let minY = -scrollView.adjustedContentInset.top
            var offset = scrollView.contentOffset
            offset.y = max(minY, offset.y + signedDeltaY)
            scrollView.setContentOffset(offset, animated: false)
        }
    }
}

private extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var candidate: UIView? = superview
        while let view = candidate {
            if let scrollView = view as? UIScrollView { return scrollView }
            candidate = view.superview
        }
        return nil
    }
}
