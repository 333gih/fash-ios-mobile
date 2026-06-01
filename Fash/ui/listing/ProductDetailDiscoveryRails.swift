import SwiftUI

private let pdpCompactCardWidth: CGFloat = 132

/// PDP discovery — single horizontal row (compact; avoids tall masonry stacks on detail).
struct ProductDetailCompactRail: View {
    @Environment(\.fashSpacing) private var spacing

    let title: String
    let systemImage: String
    let items: [ListingFeedItem]
    let onListingTap: (String) -> Void
    var onLike: ((ListingFeedItem) -> Void)?
    var onSave: ((ListingFeedItem) -> Void)?
    var embedInHub: Bool = false

    private var displayItems: [ListingFeedItem] {
        Array(items.prefix(ProductDetailDiscoveryConstants.railDisplayLimit))
    }

    var body: some View {
        if displayItems.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: spacing.spacing2) {
                ProductDetailComponents.sectionTitle(title, icon: systemImage)
                    .padding(.horizontal, embedInHub ? spacing.spacing2 : spacing.editorialStart)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacing.spacing2) {
                        ForEach(displayItems, id: \.id) { item in
                            ListingGridCard(
                                item: item,
                                onTap: { onListingTap(item.id) },
                                imageAspectRatio: ListingMasonryGrid.masonryAspectRatio(for: item),
                                compactFooter: true,
                                showQuickActions: onLike != nil || onSave != nil,
                                statusOverlayLabel: ListingStatusUi.overlayLabel(
                                    for: item.listingStatus,
                                    suppressActive: true
                                ),
                                onLike: onLike.map { handler in { handler(item) } },
                                onSave: onSave.map { handler in { handler(item) } }
                            )
                            .frame(width: pdpCompactCardWidth)
                            .environment(\.listingMasonryColumnWidth, pdpCompactCardWidth)
                        }
                    }
                    .padding(.horizontal, embedInHub ? spacing.spacing2 : spacing.editorialStart)
                }
            }
        }
    }
}

/// PDP discovery rails — 2-column Pinterest masonry (Explore-style; not used on PDP hub).
struct ProductDetailMasonryRail: View {
    @Environment(\.fashSpacing) private var spacing

    let title: String
    let systemImage: String
    let items: [ListingFeedItem]
    let onListingTap: (String) -> Void
    var onLike: ((ListingFeedItem) -> Void)?
    var onSave: ((ListingFeedItem) -> Void)?
    /// When true, omit outer padding — parent hub provides the card chrome.
    var embedInHub: Bool = false

    @State private var columnAssignments: [String: Bool] = [:]

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: spacing.spacing2) {
                ProductDetailComponents.sectionTitle(title, icon: systemImage)
                    .padding(.horizontal, embedInHub ? spacing.spacing2 : spacing.editorialStart)
                ListingStaggeredMasonryView(
                    items: items,
                    columnAssignments: $columnAssignments
                ) { item, _ in
                    ListingGridCard(
                        item: item,
                        onTap: { onListingTap(item.id) },
                        imageAspectRatio: ListingMasonryGrid.masonryAspectRatio(for: item),
                        showQuickActions: onLike != nil || onSave != nil,
                        statusOverlayLabel: ListingStatusUi.overlayLabel(
                            for: item.listingStatus,
                            suppressActive: true
                        ),
                        onLike: onLike.map { handler in { handler(item) } },
                        onSave: onSave.map { handler in { handler(item) } }
                    )
                }
                .padding(.horizontal, embedInHub ? spacing.spacing2 : spacing.editorialStart)
            }
            .padding(.top, embedInHub ? 0 : spacing.spacing2)
        }
    }
}
