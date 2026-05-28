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
}

/// Two-column masonry listing grid — Android `LazyVerticalStaggeredGrid` + `ListingMasonryGrid`.
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
        LazyVStack(spacing: gap) {
            ForEach(column, id: \.item.id) { entry in
                content(entry.item, entry.index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
