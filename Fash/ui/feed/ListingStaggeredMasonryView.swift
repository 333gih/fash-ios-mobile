import SwiftUI

/// Pinterest-style two-column masonry — fixed tile width, vertical stagger only.
///
/// Uses shortest-column placement with stable ids across load-more (Android `LazyVerticalStaggeredGrid`).
/// Each column is a `LazyVStack` so tiles virtualize inside the outer home `ScrollView`.
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
        .onAppear { refreshLayout() }
        .onChange(of: itemIdsSignature) { _, _ in refreshLayout() }
    }

    private var itemIdsSignature: [String] {
        items.map(\.id)
    }

    private func refreshLayout() {
        var assignments = columnAssignments
        layout = ListingMasonryGrid.makeStableColumnLayout(
            items: items,
            assignedIsRightColumn: &assignments
        )
        if assignments != columnAssignments {
            columnAssignments = assignments
        }
    }

    @ViewBuilder
    private func masonryColumn(_ column: [(index: Int, item: ListingFeedItem)]) -> some View {
        LazyVStack(spacing: gap) {
            ForEach(column, id: \.item.id) { entry in
                cellContent(entry.item, entry.index)
                    .frame(width: columnWidth, alignment: .top)
            }
        }
        .frame(width: columnWidth, alignment: .top)
    }
}
