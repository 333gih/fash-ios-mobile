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
    @State private var layoutedItemCount = 0
    @State private var containerWidth: CGFloat = 0
    @State private var layoutRefreshTask: Task<Void, Never>?

    private var gap: CGFloat { spacing.spacing2 }

    private var columnWidth: CGFloat {
        ListingMasonryGrid.feedGridColumnWidth(
            containerWidth: containerWidth > 1 ? containerWidth : UIScreen.main.bounds.width,
            spacing: spacing
        )
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
        VStack(spacing: 0) {
            widthProbe
            ForEach(feedChunks) { chunk in
                feedChunkRow(chunk)
                    .id("masonry_chunk_\(chunk.id)")
            }
            footer()
        }
        .onAppear { scheduleLayoutRefresh(forceFull: true) }
        .onChange(of: items.map(\.id)) { oldIds, newIds in
            if newIds.count < oldIds.count {
                scheduleLayoutRefresh(forceFull: true)
            } else {
                scheduleLayoutRefresh(forceFull: false)
            }
        }
        .onChange(of: engagementLayoutSignature) { _, _ in
            scheduleLayoutRefresh(forceFull: false)
        }
        .onDisappear { layoutRefreshTask?.cancel() }
    }

    private var itemsById: [String: ListingFeedItem] {
        Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }

    /// Like/save toggles keep the same ids — include engagement in layout refresh.
    private var engagementLayoutSignature: Int {
        var hasher = Hasher()
        for item in items {
            hasher.combine(item.id)
            hasher.combine(item.isLiked)
            hasher.combine(item.isSaved)
        }
        return hasher.finalize()
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
        let chunkIds = Set(chunk.entries.map(\.item.id))
        let gap = spacing.spacing2
        HStack(alignment: .top, spacing: gap) {
            feedChunkColumn(
                entries: layout.left.filter { chunkIds.contains($0.item.id) },
                gap: gap
            )
            feedChunkColumn(
                entries: layout.right.filter { chunkIds.contains($0.item.id) },
                gap: gap
            )
        }
        .padding(.leading, spacing.editorialStart)
        .padding(.trailing, spacing.editorialEnd)
    }

    @ViewBuilder
    private func feedChunkColumn(
        entries: [(index: Int, item: ListingFeedItem)],
        gap: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(entries, id: \.item.id) { entry in
                let liveItem = itemsById[entry.item.id] ?? entry.item
                let tileHeight = ListingMasonryGrid.tileHeight(columnWidth: columnWidth, item: liveItem)
                cell(liveItem, entry.index)
                    .id(liveItem.masonryCellId)
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
            layoutedItemCount = 0
            return
        }
        let fullRelayout = forceFull
            || layout.isEmpty
            || items.count < layoutedItemCount
            || columnWidth <= 1

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
