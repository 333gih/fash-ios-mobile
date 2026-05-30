import SwiftUI

/// Pinterest two-column masonry — shortest-column layout, real image heights, column-chunk virtualization.
///
/// Chunks **each column** separately (not sequential page ids) so fast scroll does not leave white gaps.
struct ListingStaggeredMasonryView<Cell: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let items: [ListingFeedItem]
    @Binding var columnAssignments: [String: Bool]
    var chunkSize: Int = ListingMasonryFeedPages.defaultChunkSize
    @ViewBuilder let cellContent: (ListingFeedItem, Int) -> Cell

    @State private var layout: ListingMasonryColumnLayout = .empty
    @State private var containerWidth: CGFloat = 0

    private var gap: CGFloat { spacing.spacing2 }
    private var edgeStart: CGFloat { spacing.editorialStart }
    private var edgeEnd: CGFloat { spacing.editorialEnd }
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

    private var columnChunks: [ListingMasonryFeedPages.Chunk] {
        ListingMasonryFeedPages.columnChunks(layout: layout, pageSize: chunkSize)
    }

    var body: some View {
        ZStack(alignment: .top) {
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

            LazyVStack(spacing: gap) {
                ForEach(columnChunks) { chunk in
                    HStack(alignment: .top, spacing: gap) {
                        masonryColumnChunk(chunk.left)
                        masonryColumnChunk(chunk.right)
                    }
                }
            }
            .frame(width: gridBlockWidth, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, symmetricInset)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onPreferenceChange(ListingMasonryContainerWidthKey.self) { width in
            guard width > 1, abs(width - containerWidth) > 0.5 else { return }
            containerWidth = width
            refreshLayout()
        }
        .onAppear { refreshLayout() }
        .onChange(of: itemIdsSignature) { _, _ in refreshLayout() }
    }

    private var itemIdsSignature: [String] {
        items.map(\.id)
    }

    private func refreshLayout() {
        var assignments = columnAssignments
        let newLayout = ListingMasonryGrid.makeStableColumnLayout(
            items: items,
            columnWidth: columnWidth,
            verticalGap: gap,
            assignedIsRightColumn: &assignments
        )
        layout = newLayout
        guard assignments != columnAssignments else { return }
        let pending = assignments
        Task { @MainActor in
            columnAssignments = pending
        }
    }

    @ViewBuilder
    private func masonryColumnChunk(_ entries: [(index: Int, item: ListingFeedItem)]) -> some View {
        VStack(spacing: gap) {
            ForEach(entries, id: \.item.id) { entry in
                let tileHeight = ListingMasonryGrid.tileHeight(
                    columnWidth: columnWidth,
                    item: entry.item
                )
                cellContent(entry.item, entry.index)
                    .environment(\.listingMasonryColumnWidth, columnWidth)
                    .frame(width: columnWidth, height: tileHeight, alignment: .top)
                    .frame(maxWidth: columnWidth)
                    .clipped()
            }
        }
        .frame(width: columnWidth, alignment: .top)
    }
}

private struct ListingMasonryColumnWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    var listingMasonryColumnWidth: CGFloat? {
        get { self[ListingMasonryColumnWidthKey.self] }
        set { self[ListingMasonryColumnWidthKey.self] = newValue }
    }
}

/// Alias for Pinterest-style masonry engine.
typealias ListingPinterestMasonryView = ListingStaggeredMasonryView
