import SwiftUI

/// Pinterest masonry — tile height from API cover pixels, shortest-column placement.
enum ListingMasonryGrid {
    /// Home / Explore / Profile listing grids — edge-to-edge; only [columnGap] between columns.
    static let feedGridHorizontalInset: CGFloat = 0

    /// Fallback when API omits dimensions (typical product photo 4:5).
    static let defaultAspectWidthOverHeight: CGFloat = 4.0 / 5.0

    /// Soft bounds on width/height ratio (w/h) — allow tall portraits and wide banners.
    private static let minAspectWidthOverHeight: CGFloat = 0.3
    private static let maxAspectWidthOverHeight: CGFloat = 2.5

    /// width / height from cover pixels; neutral default when missing.
    static func tileAspectWidthOverHeight(for item: ListingFeedItem) -> CGFloat {
        guard let w = item.coverImageWidth, let h = item.coverImageHeight, w > 0, h > 0 else {
            return defaultAspectWidthOverHeight
        }
        let raw = CGFloat(w) / CGFloat(h)
        return min(max(raw, minAspectWidthOverHeight), maxAspectWidthOverHeight)
    }

    /// Pinterest: cardHeight = columnWidth * imageHeight / imageWidth
    static func tileHeight(columnWidth: CGFloat, item: ListingFeedItem) -> CGFloat {
        guard columnWidth > 0 else { return 0 }
        let aspect = tileAspectWidthOverHeight(for: item)
        return columnWidth / aspect
    }

    /// Legacy name used by call sites for Coil/Kingfisher sizing (width/height ratio).
    static func masonryAspectRatio(for item: ListingFeedItem) -> CGFloat {
        tileAspectWidthOverHeight(for: item)
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

    static func estimatedTileHeight(columnWidth: CGFloat, item: ListingFeedItem) -> CGFloat {
        tileHeight(columnWidth: columnWidth, item: item)
    }

    static func estimatedColumnHeight(
        entries: [(index: Int, item: ListingFeedItem)],
        columnWidth: CGFloat,
        verticalGap: CGFloat
    ) -> CGFloat {
        guard !entries.isEmpty, columnWidth > 0 else { return 0 }
        let tiles = entries.reduce(CGFloat(0)) { partial, entry in
            partial + tileHeight(columnWidth: columnWidth, item: entry.item)
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

    /// Splits one masonry column into lazy page segments (virtualize without breaking column order).
    static func chunkColumn(
        _ column: [(index: Int, item: ListingFeedItem)],
        pageSize: Int
    ) -> [[(index: Int, item: ListingFeedItem)]] {
        guard pageSize > 0, !column.isEmpty else { return column.isEmpty ? [] : [column] }
        var result: [[(index: Int, item: ListingFeedItem)]] = []
        result.reserveCapacity((column.count + pageSize - 1) / pageSize)
        var start = 0
        while start < column.count {
            let end = min(start + pageSize, column.count)
            result.append(Array(column[start..<end]))
            start = end
        }
        return result
    }

    /// One lazy row (up to two tiles) — sequential pairing only; prefer column chunks in [ListingPinterestMasonryView].
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

/// Lazy page size for masonry column segments inside a parent `ScrollView`.
enum ListingMasonryFeedPages {
    static let defaultChunkSize = 16

    struct Chunk: Identifiable {
        let id: Int
        let left: [(index: Int, item: ListingFeedItem)]
        let right: [(index: Int, item: ListingFeedItem)]
    }

    static func columnChunks(
        layout: ListingMasonryColumnLayout,
        pageSize: Int = defaultChunkSize
    ) -> [Chunk] {
        let leftChunks = ListingMasonryGrid.chunkColumn(layout.left, pageSize: pageSize)
        let rightChunks = ListingMasonryGrid.chunkColumn(layout.right, pageSize: pageSize)
        let count = max(leftChunks.count, rightChunks.count)
        guard count > 0 else { return [] }
        return (0..<count).map { index in
            Chunk(
                id: index,
                left: leftChunks.indices.contains(index) ? leftChunks[index] : [],
                right: rightChunks.indices.contains(index) ? rightChunks[index] : []
            )
        }
    }
}

/// Two-column masonry listing grid — non-lazy; short lists only.
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

    private var distributedColumns: ListingMasonryColumnLayout {
        var fresh: [String: Bool] = [:]
        return ListingMasonryGrid.makeStableColumnLayout(
            items: entries.sorted { $0.index < $1.index }.map(\.item),
            columnWidth: 0,
            verticalGap: gap,
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
    static func distributeShortestColumn(
        entries: [(index: Int, item: ListingFeedItem)],
        columnWidth: CGFloat = 0,
        verticalGap: CGFloat = 0
    ) -> (
        left: [(index: Int, item: ListingFeedItem)],
        right: [(index: Int, item: ListingFeedItem)]
    ) {
        var freshAssignments: [String: Bool] = [:]
        let layout = makeStableColumnLayout(
            items: entries.sorted { $0.index < $1.index }.map(\.item),
            columnWidth: columnWidth,
            verticalGap: verticalGap,
            assignedIsRightColumn: &freshAssignments
        )
        return (layout.left, layout.right)
    }

    /// Shortest-column split; stable column per listing id across pagination.
    static func makeStableColumnLayout(
        items: [ListingFeedItem],
        columnWidth: CGFloat,
        verticalGap: CGFloat,
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
            let tileH: CGFloat
            if columnWidth > 0 {
                tileH = tileHeight(columnWidth: columnWidth, item: item) + verticalGap
            } else {
                tileH = 1 / tileAspectWidthOverHeight(for: item)
            }
            let placeRight: Bool
            if let stored = assignedIsRightColumn[item.id] {
                placeRight = stored
            } else {
                placeRight = leftHeight > rightHeight
                assignedIsRightColumn[item.id] = placeRight
            }
            if placeRight {
                right.append((index, item))
                rightHeight += tileH
            } else {
                left.append((index, item))
                leftHeight += tileH
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

struct ListingMasonryColumnLayout {
    var left: [(index: Int, item: ListingFeedItem)]
    var right: [(index: Int, item: ListingFeedItem)]

    static let empty = ListingMasonryColumnLayout(left: [], right: [])

    var isEmpty: Bool { left.isEmpty && right.isEmpty }
}

/// Pinterest two-column feed — column-chunked `LazyVStack` (fixes white gaps from page-id filtering).
struct ListingMasonryColumnFeed<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let layout: ListingMasonryColumnLayout
    var columnSpacing: CGFloat?
    var leadingPadding: CGFloat?
    var trailingPadding: CGFloat?
    @ViewBuilder let content: (ListingFeedItem, Int) -> Content

    @State private var containerWidth: CGFloat = 0

    private var gap: CGFloat { columnSpacing ?? spacing.spacing2 }
    private var edgeInset: CGFloat {
        leadingPadding ?? trailingPadding ?? ListingMasonryGrid.feedGridHorizontalInset
    }

    private var resolvedViewportWidth: CGFloat {
        containerWidth > 1 ? containerWidth : UIScreen.main.bounds.width
    }

    private var columnWidth: CGFloat {
        ListingMasonryGrid.columnWidth(
            containerWidth: resolvedViewportWidth,
            leadingInset: edgeInset,
            trailingInset: edgeInset,
            columnGap: gap
        )
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
            .frame(maxWidth: .infinity, alignment: .top)
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
                let tileHeight = ListingMasonryGrid.tileHeight(columnWidth: columnWidth, item: entry.item)
                content(entry.item, entry.index)
                    .environment(\.listingMasonryColumnWidth, columnWidth)
                    .frame(width: columnWidth, height: tileHeight, alignment: .top)
            }
        }
        .frame(width: columnWidth, alignment: .top)
    }
}

typealias ListingMasonryLazyColumns = ListingMasonryColumnFeed

/// @deprecated — sequential row pairs; gaps on the shorter side. Use [ListingPinterestMasonryView].
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

/// Triggers pagination when the user is within [threshold] items of the list end.
enum FeedPaginationPolicy {
    static let defaultPrefetchThreshold = 8

    static func shouldPrefetchNextPage(appearedIndex: Int, totalCount: Int, threshold: Int = defaultPrefetchThreshold) -> Bool {
        guard totalCount > 0, appearedIndex >= 0 else { return false }
        return totalCount - appearedIndex - 1 <= threshold
    }
}
