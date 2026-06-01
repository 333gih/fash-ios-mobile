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
}
