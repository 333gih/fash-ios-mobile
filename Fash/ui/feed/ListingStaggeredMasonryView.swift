import SwiftUI

/// Pinterest masonry — shortest column + **two `LazyVStack` columns** in one `ScrollView` (no nested lazy chunks).
struct ListingStaggeredMasonryView<Cell: View, Footer: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let items: [ListingFeedItem]
    @Binding var columnAssignments: [String: Bool]
    @ViewBuilder var footer: () -> Footer
    @ViewBuilder let cellContent: (ListingFeedItem, Int) -> Cell

    @State private var layout: ListingMasonryColumnLayout = .empty
    @State private var containerWidth: CGFloat = 0

    init(
        items: [ListingFeedItem],
        columnAssignments: Binding<[String: Bool]>,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder cellContent: @escaping (ListingFeedItem, Int) -> Cell
    ) {
        self.items = items
        self._columnAssignments = columnAssignments
        self.footer = footer
        self.cellContent = cellContent
    }

    private var gap: CGFloat { spacing.spacing2 }

    private var resolvedViewportWidth: CGFloat {
        containerWidth > 1 ? containerWidth : UIScreen.main.bounds.width
    }

    private var columnWidth: CGFloat {
        ListingMasonryGrid.feedGridColumnWidth(
            containerWidth: resolvedViewportWidth,
            spacing: spacing
        )
    }

    var body: some View {
        VStack(spacing: gap) {
            widthProbe

            VStack(spacing: gap) {
                HStack(alignment: .top, spacing: gap) {
                    pinterestColumn(layout.left)
                    pinterestColumn(layout.right)
                }
                .frame(maxWidth: .infinity)

                footer()
            }
            .padding(.leading, spacing.editorialStart)
            .padding(.trailing, spacing.editorialEnd)
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
    private func pinterestColumn(_ entries: [(index: Int, item: ListingFeedItem)]) -> some View {
        LazyVStack(spacing: gap) {
            ForEach(entries, id: \.item.id) { entry in
                masonryTile(entry)
            }
        }
        .frame(width: columnWidth, alignment: .top)
    }

    @ViewBuilder
    private func masonryTile(_ entry: (index: Int, item: ListingFeedItem)) -> some View {
        let tileHeight = ListingMasonryGrid.tileHeight(
            columnWidth: columnWidth,
            item: entry.item
        )
        cellContent(entry.item, entry.index)
            .environment(\.listingMasonryColumnWidth, columnWidth)
            .frame(width: columnWidth, height: max(1, tileHeight), alignment: .top)
            .clipped()
    }
}

extension ListingStaggeredMasonryView where Footer == EmptyView {
    init(
        items: [ListingFeedItem],
        columnAssignments: Binding<[String: Bool]>,
        @ViewBuilder cellContent: @escaping (ListingFeedItem, Int) -> Cell
    ) {
        self.init(
            items: items,
            columnAssignments: columnAssignments,
            footer: { EmptyView() },
            cellContent: cellContent
        )
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

typealias ListingPinterestMasonryView = ListingStaggeredMasonryView
