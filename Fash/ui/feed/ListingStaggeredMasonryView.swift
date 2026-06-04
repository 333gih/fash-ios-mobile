import SwiftUI

/// Pinterest masonry — shortest column + **two `LazyVStack` columns** in one `ScrollView` (no nested lazy chunks).
struct ListingStaggeredMasonryView<Cell: View, Footer: View>: View {
    @Environment(\.fashSpacing) private var spacing

    let items: [ListingFeedItem]
    @Binding var columnAssignments: [String: Bool]
    /// When nested in a parent `ScrollView` (profile/seller), use `true` so all columns lay out; `false` shows ~one lazy tile until scroll.
    var eagerLayout: Bool = false
    @ViewBuilder var footer: () -> Footer
    @ViewBuilder let cellContent: (ListingFeedItem, Int) -> Cell

    @State private var layout: ListingMasonryColumnLayout = .empty
    @State private var layoutedItemCount = 0
    @State private var containerWidth: CGFloat = 0

    init(
        items: [ListingFeedItem],
        columnAssignments: Binding<[String: Bool]>,
        eagerLayout: Bool = false,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder cellContent: @escaping (ListingFeedItem, Int) -> Cell
    ) {
        self.items = items
        self._columnAssignments = columnAssignments
        self.eagerLayout = eagerLayout
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
        .onChange(of: engagementLayoutSignature) { _, _ in refreshLayout() }
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

    /// Like/save updates keep the same ids — refresh cached column entries.
    private var engagementLayoutSignature: Int {
        var hasher = Hasher()
        for item in items {
            hasher.combine(item.id)
            hasher.combine(item.isLiked)
            hasher.combine(item.isSaved)
        }
        return hasher.finalize()
    }

    private var itemsById: [String: ListingFeedItem] {
        Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }

    private func refreshLayout() {
        guard !items.isEmpty else {
            layout = .empty
            layoutedItemCount = 0
            return
        }
        var assignments = columnAssignments
        let fullRelayout = layout.isEmpty || items.count < layoutedItemCount || columnWidth <= 1
        if fullRelayout {
            layout = ListingMasonryGrid.makeStableColumnLayout(
                items: items,
                columnWidth: columnWidth,
                verticalGap: gap,
                assignedIsRightColumn: &assignments
            )
            layoutedItemCount = items.count
        } else if items.count > layoutedItemCount {
            let start = layoutedItemCount
            layout = ListingMasonryGrid.extendStableColumnLayout(
                existing: layout,
                newItems: Array(items[start...]),
                startIndex: start,
                columnWidth: columnWidth,
                verticalGap: gap,
                assignedIsRightColumn: &assignments
            )
            layoutedItemCount = items.count
        }
        guard assignments != columnAssignments else { return }
        let pending = assignments
        Task { @MainActor in
            columnAssignments = pending
        }
    }

    @ViewBuilder
    private func pinterestColumn(_ entries: [(index: Int, item: ListingFeedItem)]) -> some View {
        Group {
            if eagerLayout {
                VStack(spacing: gap) {
                    ForEach(entries, id: \.item.masonryCellId) { entry in
                        masonryTile(entry)
                    }
                }
            } else {
                LazyVStack(spacing: gap) {
                    ForEach(entries, id: \.item.masonryCellId) { entry in
                        masonryTile(entry)
                    }
                }
            }
        }
        .frame(width: columnWidth, alignment: .top)
    }

    @ViewBuilder
    private func masonryTile(_ entry: (index: Int, item: ListingFeedItem)) -> some View {
        let liveItem = itemsById[entry.item.id] ?? entry.item
        let tileHeight = ListingMasonryGrid.tileHeight(
            columnWidth: columnWidth,
            item: liveItem
        )
        cellContent(liveItem, entry.index)
            .environment(\.listingMasonryColumnWidth, columnWidth)
            .frame(width: columnWidth, height: max(1, tileHeight), alignment: .top)
            .clipped()
    }
}

extension ListingStaggeredMasonryView where Footer == EmptyView {
    init(
        items: [ListingFeedItem],
        columnAssignments: Binding<[String: Bool]>,
        eagerLayout: Bool = false,
        @ViewBuilder cellContent: @escaping (ListingFeedItem, Int) -> Cell
    ) {
        self.init(
            items: items,
            columnAssignments: columnAssignments,
            eagerLayout: eagerLayout,
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
