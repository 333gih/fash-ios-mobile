import SwiftUI

/// Pinterest-style two-column masonry — fixed tile width, vertical stagger only.
///
/// Uses shortest-column placement with stable ids across load-more (Android `LazyVerticalStaggeredGrid`).
/// Virtualizes via page-sized `LazyVStack` chunks; each chunk uses non-lazy `VStack` columns (nested
/// `LazyVStack` columns inside `ScrollView` mis-measure width/height and overlap tiles).
struct ListingStaggeredMasonryView<Cell: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let items: [ListingFeedItem]
    @Binding var columnAssignments: [String: Bool]
    @ViewBuilder let cellContent: (ListingFeedItem, Int) -> Cell

    @State private var layout: ListingMasonryColumnLayout = .empty
    @State private var containerWidth: CGFloat = 0

    private var gap: CGFloat { spacing.spacing2 }
    private var edgeStart: CGFloat { spacing.editorialStart }
    private var edgeEnd: CGFloat { spacing.editorialEnd }
    /// Equal left/right inset — equal column widths (editorialEnd < editorialStart).
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

    private var chunks: [ListingMasonryFeedPages.Chunk] {
        ListingMasonryFeedPages.chunks(from: items)
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
                ForEach(chunks) { chunk in
                    chunkRow(chunk)
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
    private func chunkRow(_ chunk: ListingMasonryFeedPages.Chunk) -> some View {
        let chunkIds = Set(chunk.entries.map(\.item.id))
        HStack(alignment: .top, spacing: gap) {
            masonryColumn(layout.left.filter { chunkIds.contains($0.item.id) })
            masonryColumn(layout.right.filter { chunkIds.contains($0.item.id) })
        }
    }

    @ViewBuilder
    private func masonryColumn(_ column: [(index: Int, item: ListingFeedItem)]) -> some View {
        VStack(spacing: gap) {
            ForEach(column, id: \.item.id) { entry in
                let tileHeight = ListingMasonryGrid.estimatedTileHeight(
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
