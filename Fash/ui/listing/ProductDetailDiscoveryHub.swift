import SwiftUI

/// PDP related listings — one Explore-style 2-column masonry grid with relation badges per card.
struct ProductDetailDiscoveryHub: View {
    @Environment(\.fashSpacing) private var spacing

    let current: ListingDetail
    let entries: [ProductDiscoveryFeedEntry]
    let onListingTap: (String) -> Void
    var onLike: ((ListingFeedItem) -> Void)?
    var onSave: ((ListingFeedItem) -> Void)?

    @State private var columnAssignments: [String: Bool] = [:]

    var body: some View {
        if entries.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: spacing.spacing2) {
                hubHeader
                relationLegend
                masonryGrid
            }
            .padding(.top, spacing.spacing2)
        }
    }

    private var hubHeader: some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            Text(L10n.productDiscoveryHubTitle)
                .font(FashTypography.titleSmall.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
            Text(L10n.productDiscoveryHubSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, spacing.editorialStart)
    }

    @ViewBuilder
    private var relationLegend: some View {
        FlowLayout(spacing: 8) {
            if entries.contains(where: { $0.relation == .seller }) {
                legendChip(text: L10n.productRelationLegendSeller, systemImage: "bag.fill")
            }
            if entries.contains(where: { $0.relation == .category }) {
                legendChip(text: L10n.productRelationLegendCategory, systemImage: "square.grid.2x2")
            }
            if entries.contains(where: { $0.relation == .brand }) {
                legendChip(text: L10n.productRelationLegendBrand, systemImage: "tag.fill")
            }
            if entries.contains(where: { $0.relation == .style }) {
                legendChip(text: L10n.productRelationLegendStyle, systemImage: "sparkles")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, spacing.editorialStart)
    }

    private func legendChip(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(FashTypography.labelMedium)
        }
        .foregroundStyle(FashColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(FashColors.surfaceContainer.opacity(0.65))
        .clipShape(Capsule())
    }

    private var masonryGrid: some View {
        ListingStaggeredMasonryView(
            items: entries.map(\.item),
            columnAssignments: $columnAssignments
        ) { item, _ in
            let entry = entries.first { $0.item.id == item.id }
            ListingGridCard(
                item: item,
                onTap: { onListingTap(item.id) },
                imageAspectRatio: ListingMasonryGrid.masonryAspectRatio(for: item),
                showQuickActions: onLike != nil || onSave != nil,
                statusOverlayLabel: ListingStatusUi.overlayLabel(
                    for: item.listingStatus,
                    suppressActive: true
                ),
                relationBadgeLabel: entry?.relationLabel,
                onLike: onLike.map { handler in { handler(item) } },
                onSave: onSave.map { handler in { handler(item) } }
            )
        }
    }
}
