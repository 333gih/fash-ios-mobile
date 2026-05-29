import SwiftUI

/// Android `LazyVerticalStaggeredGrid` for Home / Explore listing feeds (embedded in `ScrollView`).
struct ListingStaggeredMasonryView<Cell: View>: View {
    @Environment(\.fashSpacing) private var spacing
    let items: [ListingFeedItem]
    @ViewBuilder let cellContent: (ListingFeedItem, Int) -> Cell

    var body: some View {
        ListingMasonryWaterfallLayout(
            columns: 2,
            columnSpacing: spacing.spacing2,
            rowSpacing: spacing.spacing2,
            leadingInset: spacing.editorialStart,
            trailingInset: spacing.editorialEnd
        ) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                cellContent(item, index)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
        }
    }
}
