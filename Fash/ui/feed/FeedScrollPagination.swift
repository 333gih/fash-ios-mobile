import SwiftUI

/// Bottom of listing feed in a named scroll space — used for end-of-scroll pagination.
struct FeedContentBottomYKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

/// Reports the max Y of content inside `coordinateSpace` (lower = closer to visible bottom when scrolled).
struct FeedScrollContentBottomReporter: View {
    let coordinateSpace: String

    var body: some View {
        Color.clear
            .frame(height: 1)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: FeedContentBottomYKey.self,
                        value: geo.frame(in: .named(coordinateSpace)).maxY
                    )
                }
            )
    }
}

enum FeedScrollPaginationPolicy {
    /// Distance from visible bottom before requesting the next page (Android: lastVisible >= size - 3).
    static let proximityThreshold: CGFloat = 320

    static func shouldLoadMore(
        headerMinY: CGFloat,
        contentBottomY: CGFloat,
        viewportHeight: CGFloat,
        hasItems: Bool,
        hasMore: Bool,
        isLoadingMore: Bool,
        isLoadingFirstPage: Bool
    ) -> Bool {
        guard hasItems, hasMore, !isLoadingMore, !isLoadingFirstPage else { return false }
        guard viewportHeight > 64, contentBottomY.isFinite, contentBottomY < .infinity else { return false }
        let scrolled = max(0, -headerMinY)
        let visibleBottom = scrolled + viewportHeight
        return contentBottomY <= visibleBottom + proximityThreshold
    }

    /// True when the feed bottom edge is visible — seller storefront end-of-screen pagination.
    static func isAtScrollBottom(
        headerMinY: CGFloat,
        contentBottomY: CGFloat,
        viewportHeight: CGFloat,
        tolerance: CGFloat = 40
    ) -> Bool {
        guard viewportHeight > 64, contentBottomY.isFinite, contentBottomY < .infinity else { return false }
        let scrolled = max(0, -headerMinY)
        let visibleBottom = scrolled + viewportHeight
        return contentBottomY <= visibleBottom + tolerance
    }
}

/// One-shot bottom pagination — re-arms only after the user scrolls up (avoids load loops when content grows).
struct FeedBottomLoadMoreGate {
    private(set) var isArmed = true
    private var peakScrolled: CGFloat = 0
    private var lastLoadAt = Date.distantPast
    var cooldown: TimeInterval = 0.85
    var rearmScrollDelta: CGFloat = 56

    mutating func reset() {
        isArmed = true
        peakScrolled = 0
        lastLoadAt = .distantPast
    }

    mutating func noteScrollOffset(headerMinY: CGFloat) {
        let scrolled = max(0, -headerMinY)
        if scrolled < peakScrolled - rearmScrollDelta {
            isArmed = true
            peakScrolled = scrolled
        } else {
            peakScrolled = max(peakScrolled, scrolled)
        }
    }

    mutating func tryConsumeAtBottom(
        headerMinY: CGFloat,
        contentBottomY: CGFloat,
        viewportHeight: CGFloat,
        tolerance: CGFloat,
        hasMore: Bool,
        isLoadingMore: Bool
    ) -> Bool {
        guard hasMore, !isLoadingMore, isArmed else { return false }
        let now = Date()
        guard now.timeIntervalSince(lastLoadAt) >= cooldown else { return false }
        guard FeedScrollPaginationPolicy.isAtScrollBottom(
            headerMinY: headerMinY,
            contentBottomY: contentBottomY,
            viewportHeight: viewportHeight,
            tolerance: tolerance
        ) else { return false }
        isArmed = false
        lastLoadAt = now
        return true
    }
}
