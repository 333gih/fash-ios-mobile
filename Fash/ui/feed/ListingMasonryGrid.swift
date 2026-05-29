import SwiftUI

/// Port of Android `ListingMasonryGrid` (ui.feed).
enum ListingMasonryGrid {
    private static let staggerRatios: [CGFloat] = [3.0 / 4.0, 4.0 / 5.0, 5.0 / 6.0]

    /// Vary tile height by listing id hash — Android `listingMasonryStaggerAspectRatio`.
    static func staggerAspectRatio(for listingId: String) -> CGFloat {
        let bucket = abs(javaStringHashCode(listingId)) % staggerRatios.count
        return staggerRatios[bucket]
    }

    /// JVM/Kotlin `String.hashCode()` — stable bucket parity with Android.
    private static func javaStringHashCode(_ value: String) -> Int {
        var hash = 0
        for unit in value.utf16 {
            hash = 31 &* hash &+ Int(unit)
        }
        return hash
    }

    /// One lazy row (up to two tiles) — Android `listingMasonryFeedRows` for long feeds.
    struct FeedRow: Identifiable {
        let id: String
        let left: (index: Int, item: ListingFeedItem)
        let right: (index: Int, item: ListingFeedItem)?

        static func build(from items: [ListingFeedItem]) -> [FeedRow] {
            guard !items.isEmpty else { return [] }
            var rows: [FeedRow] = []
            rows.reserveCapacity((items.count + 1) / 2)
            var index = 0
            while index < items.count {
                let leftItem = items[index]
                let left = (index, leftItem)
                let right: (Int, ListingFeedItem)?
                if index + 1 < items.count {
                    right = (index + 1, items[index + 1])
                } else {
                    right = nil
                }
                rows.append(FeedRow(id: leftItem.id, left: left, right: right))
                index += 2
            }
            return rows
        }
    }
}

/// Two-column masonry listing grid — Android `ListingMasonryGrid` (non-lazy columns).
///
/// Uses `VStack` per column instead of nested `LazyVStack` inside `ScrollView`, which causes
/// phantom gaps while loading or fast-scrolling (SwiftUI nested-lazy height miscalculation).
struct ListingMasonryGridView<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let items: [ListingFeedItem]
    var columnSpacing: CGFloat?
    var leadingPadding: CGFloat?
    var trailingPadding: CGFloat?
    @ViewBuilder let content: (ListingFeedItem, Int) -> Content

    private var gap: CGFloat { columnSpacing ?? spacing.spacing2 }
    private var edgeStart: CGFloat { leadingPadding ?? spacing.editorialStart }
    private var edgeEnd: CGFloat { trailingPadding ?? spacing.editorialEnd }

    private var leftColumn: [(index: Int, item: ListingFeedItem)] {
        items.enumerated().compactMap { index, item in
            index.isMultiple(of: 2) ? (index, item) : nil
        }
    }

    private var rightColumn: [(index: Int, item: ListingFeedItem)] {
        items.enumerated().compactMap { index, item in
            index.isMultiple(of: 2) ? nil : (index, item)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: gap) {
            masonryColumn(leftColumn)
            masonryColumn(rightColumn)
        }
        .padding(.leading, edgeStart)
        .padding(.trailing, edgeEnd)
    }

    @ViewBuilder
    private func masonryColumn(_ column: [(index: Int, item: ListingFeedItem)]) -> some View {
        VStack(spacing: gap) {
            ForEach(column, id: \.item.id) { entry in
                content(entry.item, entry.index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

/// Virtualized **row pairs** for long feeds (`ScrollView` + `LazyVStack`).
///
/// Prefer [ListingMasonryGridView] when visual parity with Home/Android staggered grid matters:
/// row pairs use `max(leftHeight, rightHeight)` per row, which adds extra vertical gaps between tiles.
struct ListingMasonryLazyRows<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let items: [ListingFeedItem]
    var columnSpacing: CGFloat?
    var leadingPadding: CGFloat?
    var trailingPadding: CGFloat?
    @ViewBuilder let content: (ListingFeedItem, Int) -> Content

    private var gap: CGFloat { columnSpacing ?? spacing.spacing2 }
    private var edgeStart: CGFloat { leadingPadding ?? spacing.editorialStart }
    private var edgeEnd: CGFloat { trailingPadding ?? spacing.editorialEnd }

    private var rows: [ListingMasonryGrid.FeedRow] {
        ListingMasonryGrid.FeedRow.build(from: items)
    }

    var body: some View {
        ForEach(rows) { row in
            HStack(alignment: .top, spacing: gap) {
                content(row.left.item, row.left.index)
                    .frame(maxWidth: .infinity)
                if let right = row.right {
                    content(right.item, right.index)
                        .frame(maxWidth: .infinity)
                } else {
                    // Keeps two-column row width stable when the last row has a single tile.
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }
            .padding(.leading, edgeStart)
            .padding(.trailing, edgeEnd)
        }
    }
}
