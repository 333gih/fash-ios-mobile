import SwiftUI

/// PDP related listings — one connected surface so rails feel linked to the current product.
struct ProductDetailDiscoveryHub: View {
    @Environment(\.fashSpacing) private var spacing

    let current: ListingDetail
    let sellerLabel: String
    let sellerItems: [ListingFeedItem]
    let categoryLabel: String?
    let categoryItems: [ListingFeedItem]
    let brandLabel: String?
    let brandItems: [ListingFeedItem]
    let styleItems: [ListingFeedItem]
    let onListingTap: (String) -> Void
    var onLike: ((ListingFeedItem) -> Void)?
    var onSave: ((ListingFeedItem) -> Void)?

    private var hasAnyRail: Bool {
        !sellerItems.isEmpty || !categoryItems.isEmpty || !brandItems.isEmpty || !styleItems.isEmpty
    }

    var body: some View {
        if !hasAnyRail {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: spacing.spacing2) {
                hubHeader
                connectedRailsCard
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
            relationChips
        }
        .padding(.horizontal, spacing.editorialStart)
    }

    @ViewBuilder
    private var relationChips: some View {
        FlowLayout(spacing: 8) {
            if let cat = current.category?.nilIfEmpty {
                relationChip(text: cat, systemImage: "square.grid.2x2")
            }
            if let brand = current.brand?.nilIfEmpty {
                relationChip(text: brand, systemImage: "tag.fill")
            }
            if let seller = current.sellerUsername?.nilIfEmpty ?? current.sellerDisplayName?.nilIfEmpty {
                relationChip(text: "@\(seller)", systemImage: "bag.fill")
            }
            ForEach(current.aestheticTagRefs.prefix(3), id: \.label) { tag in
                if !tag.label.isEmpty {
                    relationChip(text: tag.label, systemImage: "sparkles")
                }
            }
        }
    }

    private func relationChip(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(FashTypography.labelMedium)
                .lineLimit(1)
        }
        .foregroundStyle(FashColors.brandPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(FashColors.brandPrimary.opacity(0.1))
        .clipShape(Capsule())
    }

    private var connectedRailsCard: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FashColors.brandPrimary, FashColors.brandPrimary.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, spacing.spacing2)

            VStack(alignment: .leading, spacing: 0) {
                if !sellerItems.isEmpty {
                    connectedRail(
                        title: L10n.productMoreFromSeller(sellerLabel),
                        icon: "bag.fill",
                        items: sellerItems,
                        showsTopDivider: false
                    )
                }
                if !categoryItems.isEmpty, let categoryLabel {
                    connectedRail(
                        title: L10n.productRelatedCategory(categoryLabel),
                        icon: "square.grid.2x2",
                        items: categoryItems,
                        showsTopDivider: !sellerItems.isEmpty
                    )
                }
                if !brandItems.isEmpty, let brandLabel {
                    connectedRail(
                        title: L10n.productRelatedBrand(brandLabel),
                        icon: "tag.fill",
                        items: brandItems,
                        showsTopDivider: !(sellerItems.isEmpty && categoryItems.isEmpty)
                    )
                }
                if !styleItems.isEmpty {
                    connectedRail(
                        title: L10n.productRelatedStyle,
                        icon: "sparkles",
                        items: styleItems,
                        showsTopDivider: !(sellerItems.isEmpty && categoryItems.isEmpty && brandItems.isEmpty)
                    )
                }
            }
            .padding(.vertical, spacing.spacing2)
        }
        .background(FashColors.surfaceContainer.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FashColors.outlineMuted.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal, spacing.editorialStart)
    }

    @ViewBuilder
    private func connectedRail(
        title: String,
        icon: String,
        items: [ListingFeedItem],
        showsTopDivider: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            if showsTopDivider {
                Divider().opacity(0.45).padding(.horizontal, spacing.spacing2)
            }
            ProductDetailMasonryRail(
                title: title,
                systemImage: icon,
                items: items,
                onListingTap: onListingTap,
                onLike: onLike,
                onSave: onSave,
                embedInHub: true
            )
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
