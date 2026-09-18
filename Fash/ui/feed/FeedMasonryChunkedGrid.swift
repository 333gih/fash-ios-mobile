import SwiftUI

/// Chunked Pinterest grid for feeds inside a parent `ScrollView` — avoids nested `LazyVStack` showing one tile.
struct FeedMasonryChunkedGrid<Cell: View, Footer: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let items: [ListingFeedItem]
    @Binding var columnAssignments: [String: Bool]
    var chunkSize: Int = ListingMasonryFeedPages.profileChunkPageSize
    @ViewBuilder var footer: () -> Footer
    @ViewBuilder let cell: (ListingFeedItem, Int) -> Cell

    @State private var layout: ListingMasonryColumnLayout = .empty
    @State private var perChunkLayout: [Int: ChunkColumns] = [:]
    @State private var layoutedItemCount = 0
    @State private var containerWidth: CGFloat = 0
    @State private var layoutRefreshTask: Task<Void, Never>?

    private struct ChunkColumns {
        let left: [(index: Int, item: ListingFeedItem)]
        let right: [(index: Int, item: ListingFeedItem)]
    }

    // O(1) identity check — replaces O(n) items.map(\.id) on every state change.
    private struct ItemsSignature: Equatable {
        let count: Int
        let firstId: String
    }

    private var gap: CGFloat { spacing.spacing2 }

    private var columnWidth: CGFloat {
        ListingMasonryGrid.feedGridColumnWidth(
            containerWidth: containerWidth > 1 ? containerWidth : UIScreen.main.bounds.width,
            spacing: spacing
        )
    }

    private var itemsSignature: ItemsSignature {
        ItemsSignature(count: items.count, firstId: items.first?.id ?? "")
    }

    init(
        items: [ListingFeedItem],
        columnAssignments: Binding<[String: Bool]>,
        chunkSize: Int = ListingMasonryFeedPages.profileChunkPageSize,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder cell: @escaping (ListingFeedItem, Int) -> Cell
    ) {
        self.items = items
        self._columnAssignments = columnAssignments
        self.chunkSize = chunkSize
        self.footer = footer
        self.cell = cell
    }

    var body: some View {
        VStack(spacing: gap) {
            widthProbe
            ForEach(feedChunks) { chunk in
                feedChunkRow(chunk)
                    .id("masonry_chunk_\(chunk.id)")
            }
            footer()
        }
        .onAppear { refreshLayout(forceFull: true) }
        .onChange(of: itemsSignature) { old, new in
            guard old != new else { return }
            // Count grew and first item is unchanged → trailing pagination append.
            if new.count > old.count && new.firstId == old.firstId {
                refreshLayout(forceFull: false)
            } else {
                refreshLayout(forceFull: true)
            }
        }
        .onDisappear { layoutRefreshTask?.cancel() }
    }

    private var feedChunks: [ListingMasonryFeedPages.FeedOrderChunk] {
        ListingMasonryFeedPages.feedOrderChunks(items: items, pageSize: chunkSize)
    }

    private var widthProbe: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: 0)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ListingMasonryContainerWidthKey.self,
                        value: proxy.size.width
                    )
                }
            }
            .onPreferenceChange(ListingMasonryContainerWidthKey.self) { width in
                guard width > 1, abs(width - containerWidth) > 0.5 else { return }
                containerWidth = width
                scheduleLayoutRefresh(forceFull: true)
            }
    }

    @ViewBuilder
    private func feedChunkRow(_ chunk: ListingMasonryFeedPages.FeedOrderChunk) -> some View {
        let gap = spacing.spacing2
        // O(1) dict lookup — perChunkLayout is pre-built in rebuildPerChunkLayout().
        // Falls back to alternating assignment so the first render shows tiles immediately
        // (before onAppear fires the full layout pass) instead of blank empty rows.
        let cols = perChunkLayout[chunk.id] ?? chunkFallbackColumns(chunk)
        HStack(alignment: .top, spacing: gap) {
            feedChunkColumn(entries: cols.left, gap: gap)
            feedChunkColumn(entries: cols.right, gap: gap)
        }
        .padding(.leading, spacing.editorialStart)
        .padding(.trailing, spacing.editorialEnd)
    }

    private func chunkFallbackColumns(_ chunk: ListingMasonryFeedPages.FeedOrderChunk) -> ChunkColumns {
        var left = [(index: Int, item: ListingFeedItem)]()
        var right = [(index: Int, item: ListingFeedItem)]()
        for (i, entry) in chunk.entries.enumerated() {
            if i.isMultiple(of: 2) { left.append(entry) } else { right.append(entry) }
        }
        return ChunkColumns(left: left, right: right)
    }

    @ViewBuilder
    private func feedChunkColumn(
        entries: [(index: Int, item: ListingFeedItem)],
        gap: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(entries, id: \.item.id) { entry in
                // O(1) index-based lookup picks up latest like/save state (e.g. after a like tap).
                // ID guard prevents showing wrong items during the 48ms layout-refresh delay window.
                let liveItem: ListingFeedItem = {
                    guard entry.index < items.count,
                          items[entry.index].id == entry.item.id else { return entry.item }
                    return items[entry.index]
                }()
                let tileHeight = ListingMasonryGrid.tileHeight(columnWidth: columnWidth, item: liveItem)
                cell(liveItem, entry.index)
                    .id(liveItem.id)
                    .environment(\.listingMasonryColumnWidth, columnWidth)
                    .frame(width: columnWidth, height: max(1, tileHeight), alignment: .top)
                    .clipped()
            }
        }
        .frame(width: columnWidth, alignment: .top)
    }

    private func scheduleLayoutRefresh(forceFull: Bool) {
        layoutRefreshTask?.cancel()
        layoutRefreshTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(forceFull ? 0 : 48))
            guard !Task.isCancelled else { return }
            refreshLayout(forceFull: forceFull)
        }
    }

    private func refreshLayout(forceFull: Bool) {
        guard !items.isEmpty else {
            layout = .empty
            perChunkLayout = [Int: ChunkColumns]()
            layoutedItemCount = 0
            return
        }
        let fullRelayout = forceFull
            || layout.isEmpty
            || items.count < layoutedItemCount
            || columnWidth <= 1
            || !layoutMatchesCurrentItems()

        if fullRelayout {
            var assignments = columnAssignments
            layout = ListingMasonryGrid.makeStableColumnLayout(
                items: items,
                columnWidth: columnWidth,
                verticalGap: gap,
                assignedIsRightColumn: &assignments
            )
            if assignments != columnAssignments {
                columnAssignments = assignments
            }
            layoutedItemCount = items.count
            rebuildPerChunkLayout()
            return
        }

        guard items.count > layoutedItemCount else { return }
        let start = layoutedItemCount
        let newSlice = Array(items[start...])
        var assignments = columnAssignments
        layout = ListingMasonryGrid.extendStableColumnLayout(
            existing: layout,
            newItems: newSlice,
            startIndex: start,
            columnWidth: columnWidth,
            verticalGap: gap,
            assignedIsRightColumn: &assignments
        )
        if assignments != columnAssignments {
            columnAssignments = assignments
        }
        layoutedItemCount = items.count
        rebuildPerChunkLayout()
    }

    // O(n) single-pass split: assigns each layout entry to its chunk without per-chunk filtering.
    private func rebuildPerChunkLayout() {
        let chunks = ListingMasonryFeedPages.feedOrderChunks(items: items, pageSize: chunkSize)
        // Build itemId → chunkId (Int) index in one pass over chunks.
        var itemToChunk: [String: Int] = [:]
        itemToChunk.reserveCapacity(items.count)
        for chunk in chunks {
            for entry in chunk.entries {
                itemToChunk[entry.item.id] = chunk.id
            }
        }
        // Single pass over layout columns to bucket entries by chunk.
        var leftByChunk: [Int: [(index: Int, item: ListingFeedItem)]] = [:]
        var rightByChunk: [Int: [(index: Int, item: ListingFeedItem)]] = [:]
        for entry in layout.left {
            if let cid = itemToChunk[entry.item.id] {
                leftByChunk[cid, default: []].append(entry)
            }
        }
        for entry in layout.right {
            if let cid = itemToChunk[entry.item.id] {
                rightByChunk[cid, default: []].append(entry)
            }
        }
        var result: [Int: ChunkColumns] = [:]
        result.reserveCapacity(chunks.count)
        for chunk in chunks {
            result[chunk.id] = ChunkColumns(
                left: leftByChunk[chunk.id] ?? [],
                right: rightByChunk[chunk.id] ?? []
            )
        }
        perChunkLayout = result
    }

    private func layoutMatchesCurrentItems() -> Bool {
        guard !layout.isEmpty, layoutedItemCount == items.count else { return false }
        let layoutIds = layout.left.map(\.item.id) + layout.right.map(\.item.id)
        guard layoutIds.count == items.count else { return false }
        return zip(layoutIds, items.map(\.id)).allSatisfy { $0.0 == $0.1 }
    }
}

extension FeedMasonryChunkedGrid where Footer == EmptyView {
    init(
        items: [ListingFeedItem],
        columnAssignments: Binding<[String: Bool]>,
        chunkSize: Int = ListingMasonryFeedPages.profileChunkPageSize,
        @ViewBuilder cell: @escaping (ListingFeedItem, Int) -> Cell
    ) {
        self.init(
            items: items,
            columnAssignments: columnAssignments,
            chunkSize: chunkSize,
            footer: { EmptyView() },
            cell: cell
        )
    }
}
