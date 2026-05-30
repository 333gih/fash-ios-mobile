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

    /// Tile height when the column width is known (image aspect ratio only).
    static func estimatedTileHeight(columnWidth: CGFloat, listingId: String) -> CGFloat {
        guard columnWidth > 0 else { return 0 }
        return columnWidth / staggerAspectRatio(for: listingId)
    }

    static func columnWidth(
        containerWidth: CGFloat,
        leadingInset: CGFloat,
        trailingInset: CGFloat,
        columnGap: CGFloat
    ) -> CGFloat {
        let inner = max(0, containerWidth - leadingInset - trailingInset - columnGap)
        return inner / 2
    }

    static func estimatedColumnHeight(
        entries: [(index: Int, item: ListingFeedItem)],
        columnWidth: CGFloat,
        verticalGap: CGFloat
    ) -> CGFloat {
        guard !entries.isEmpty, columnWidth > 0 else { return 0 }
        let tiles = entries.reduce(CGFloat(0)) { partial, entry in
            partial + estimatedTileHeight(columnWidth: columnWidth, listingId: entry.item.id)
        }
        return tiles + verticalGap * CGFloat(max(0, entries.count - 1))
    }

    static func estimatedGridHeight(
        layout: ListingMasonryColumnLayout,
        columnWidth: CGFloat,
        verticalGap: CGFloat
    ) -> CGFloat {
        max(
            estimatedColumnHeight(entries: layout.left, columnWidth: columnWidth, verticalGap: verticalGap),
            estimatedColumnHeight(entries: layout.right, columnWidth: columnWidth, verticalGap: verticalGap)
        )
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

/// Page-sized chunks for optional batching. [ListingStaggeredMasonryView] lazy-loads chunks over the full list.
enum ListingMasonryFeedPages {
    /// Matches Explore/Home listing page size (`exploreFeedPageSize`).
    static let defaultChunkSize = 20

    struct Chunk: Identifiable {
        let id: Int
        let entries: [(index: Int, item: ListingFeedItem)]
    }

    static func chunks(from items: [ListingFeedItem], pageSize: Int = defaultChunkSize) -> [Chunk] {
        guard !items.isEmpty, pageSize > 0 else { return [] }
        var result: [Chunk] = []
        result.reserveCapacity((items.count + pageSize - 1) / pageSize)
        var pageIndex = 0
        var start = 0
        while start < items.count {
            let end = min(start + pageSize, items.count)
            let entries = (start..<end).map { ($0, items[$0]) }
            result.append(Chunk(id: pageIndex, entries: entries))
            pageIndex += 1
            start = end
        }
        return result
    }
}

/// Two-column masonry listing grid — Android `ListingMasonryGrid` (non-lazy columns).
///
/// Uses `VStack` per column instead of nested `LazyVStack` inside `ScrollView`, which causes
/// phantom gaps while loading or fast-scrolling (SwiftUI nested-lazy height miscalculation).
struct ListingMasonryGridView<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let entries: [(index: Int, item: ListingFeedItem)]
    var columnSpacing: CGFloat?
    var leadingPadding: CGFloat?
    var trailingPadding: CGFloat?
    @ViewBuilder let content: (ListingFeedItem, Int) -> Content

    init(
        items: [ListingFeedItem],
        columnSpacing: CGFloat? = nil,
        leadingPadding: CGFloat? = nil,
        trailingPadding: CGFloat? = nil,
        @ViewBuilder content: @escaping (ListingFeedItem, Int) -> Content
    ) {
        self.entries = items.enumerated().map { ($0.offset, $0.element) }
        self.columnSpacing = columnSpacing
        self.leadingPadding = leadingPadding
        self.trailingPadding = trailingPadding
        self.content = content
    }

    init(
        entries: [(index: Int, item: ListingFeedItem)],
        columnSpacing: CGFloat? = nil,
        leadingPadding: CGFloat? = nil,
        trailingPadding: CGFloat? = nil,
        @ViewBuilder content: @escaping (ListingFeedItem, Int) -> Content
    ) {
        self.entries = entries
        self.columnSpacing = columnSpacing
        self.leadingPadding = leadingPadding
        self.trailingPadding = trailingPadding
        self.content = content
    }

    private var gap: CGFloat { columnSpacing ?? spacing.spacing2 }
    private var edgeStart: CGFloat { leadingPadding ?? spacing.editorialStart }
    private var edgeEnd: CGFloat { trailingPadding ?? spacing.editorialEnd }

    /// Shortest-column masonry — balances column heights using stagger aspect ratios (Android StaggeredGrid).
    private var distributedColumns: ListingMasonryColumnLayout {
        var fresh: [String: Bool] = [:]
        return ListingMasonryGrid.makeStableColumnLayout(
            items: entries.sorted { $0.index < $1.index }.map(\.item),
            assignedIsRightColumn: &fresh
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: gap) {
            masonryColumn(distributedColumns.left)
            masonryColumn(distributedColumns.right)
        }
        .padding(.leading, edgeStart)
        .padding(.trailing, edgeEnd)
    }

    @ViewBuilder
    private func masonryColumn(_ column: [(index: Int, item: ListingFeedItem)]) -> some View {
        VStack(spacing: gap) {
            ForEach(column, id: \.item.id) { entry in
                content(entry.item, entry.index)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

extension ListingMasonryGrid {
    /// Assigns each tile to the shorter column using estimated height from [staggerAspectRatio].
    static func distributeShortestColumn(
        entries: [(index: Int, item: ListingFeedItem)]
    ) -> (
        left: [(index: Int, item: ListingFeedItem)],
        right: [(index: Int, item: ListingFeedItem)]
    ) {
        var freshAssignments: [String: Bool] = [:]
        let layout = makeStableColumnLayout(
            items: entries.sorted { $0.index < $1.index }.map(\.item),
            assignedIsRightColumn: &freshAssignments
        )
        return (layout.left, layout.right)
    }

    /// Masonry split with **stable** column per listing id — existing tiles do not move when appending pages.
    static func makeStableColumnLayout(
        items: [ListingFeedItem],
        assignedIsRightColumn: inout [String: Bool]
    ) -> ListingMasonryColumnLayout {
        let liveIds = Set(items.map(\.id))
        assignedIsRightColumn = assignedIsRightColumn.filter { liveIds.contains($0.key) }

        guard !items.isEmpty else { return .empty }

        var left: [(index: Int, item: ListingFeedItem)] = []
        var right: [(index: Int, item: ListingFeedItem)] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0
        left.reserveCapacity(items.count / 2 + 1)
        right.reserveCapacity(items.count / 2 + 1)

        for (index, item) in items.enumerated() {
            let unitHeight = 1 / staggerAspectRatio(for: item.id)
            let placeRight: Bool
            if let stored = assignedIsRightColumn[item.id] {
                placeRight = stored
            } else {
                // New tile (e.g. load-more batch) → shorter column first.
                placeRight = leftHeight > rightHeight
                assignedIsRightColumn[item.id] = placeRight
            }
            if placeRight {
                right.append((index, item))
                rightHeight += unitHeight
            } else {
                left.append((index, item))
                leftHeight += unitHeight
            }
        }
        return ListingMasonryColumnLayout(left: left, right: right)
    }
}

struct ListingMasonryContainerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 { value = next }
    }
}

/// Two-column masonry layout — left/right item lists with global indices.
struct ListingMasonryColumnLayout {
    var left: [(index: Int, item: ListingFeedItem)]
    var right: [(index: Int, item: ListingFeedItem)]

    static let empty = ListingMasonryColumnLayout(left: [], right: [])

    var isEmpty: Bool { left.isEmpty && right.isEmpty }
}

/// Two-column masonry with **fixed equal tile widths** — Android `LazyVerticalStaggeredGrid` parity.
///
/// Uses non-lazy `VStack` columns (nested `LazyVStack` in `ScrollView` overlaps tiles). Pair with
/// [ListingMasonryGrid.makeStableColumnLayout] for stable load-more placement.
struct ListingMasonryColumnFeed<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let layout: ListingMasonryColumnLayout
    var columnSpacing: CGFloat?
    var leadingPadding: CGFloat?
    var trailingPadding: CGFloat?
    @ViewBuilder let content: (ListingFeedItem, Int) -> Content

    @State private var containerWidth: CGFloat = 0

    private var gap: CGFloat { columnSpacing ?? spacing.spacing2 }
    private var edgeStart: CGFloat { leadingPadding ?? spacing.editorialStart }
    private var edgeEnd: CGFloat { trailingPadding ?? spacing.editorialEnd }
    /// Equal left/right inset — avoids lopsided grid (editorialEnd is smaller than editorialStart).
    private var symmetricInset: CGFloat { max(edgeStart, edgeEnd) }

    private var resolvedViewportWidth: CGFloat {
        containerWidth > 1 ? containerWidth : UIScreen.main.bounds.width
    }

    private var columnWidth: CGFloat {
        ListingMasonryGrid.columnWidth(
            containerWidth: resolvedViewportWidth,
            leadingInset: symmetricInset,
            trailingInset: symmetricInset,
            columnGap: gap
        )
    }

    private var gridBlockWidth: CGFloat {
        max(0, columnWidth * 2 + gap)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: 0)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: ListingMasonryContainerWidthKey.self,
                                value: proxy.size.width
                            )
                    }
                )

            HStack(alignment: .top, spacing: gap) {
                masonryColumn(layout.left)
                masonryColumn(layout.right)
            }
            .frame(width: gridBlockWidth, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, symmetricInset)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onPreferenceChange(ListingMasonryContainerWidthKey.self) { width in
            guard width > 1, abs(width - containerWidth) > 0.5 else { return }
            containerWidth = width
        }
    }

    @ViewBuilder
    private func masonryColumn(_ column: [(index: Int, item: ListingFeedItem)]) -> some View {
        VStack(spacing: gap) {
            ForEach(column, id: \.item.id) { entry in
                content(entry.item, entry.index)
                    .frame(width: columnWidth, alignment: .top)
            }
        }
        .frame(width: columnWidth, alignment: .top)
    }
}

/// Backward-compatible name — routes to [ListingMasonryColumnFeed].
typealias ListingMasonryLazyColumns = ListingMasonryColumnFeed

/// Virtualized **row pairs** for long feeds (`ScrollView` + `LazyVStack`) — Android `listingMasonryFeedRows`.
///
/// Prefer [ListingMasonryLazyColumns] for equal-width staggered columns; row pairs leave gaps on the shorter side.
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
