import SwiftUI

struct OutfitSetDetailScreen: View {
    @Environment(\.fashSpacing) private var spacing
    let set: OutfitSetCard
    var onDismiss: () -> Void
    var onItemClick: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        FashScreenScaffold(
            title: set.title.isEmpty ? L10n.outfitSetDetailTitle : String(set.title.prefix(48)),
            showBack: true,
            onBack: onDismiss
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.spacing3) {
                    if !set.reasonLabel.isEmpty {
                        Text(set.reasonLabel)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    Text(L10n.outfitSetDetailHint)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(set.items) { item in
                            outfitItemCard(item)
                                .onTapGesture { onItemClick(item.listingId) }
                        }
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.vertical, spacing.spacing3)
            }
            .background(FashColors.screen)
        }
    }

    @ViewBuilder
    private func outfitItemCard(_ item: OutfitSetItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FashAsyncImage(url: item.coverImageUrl, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .aspectRatio(3 / 4, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))

            Text(OutfitSlotLabels.label(for: item.slotRole))
                .font(FashTypography.labelSmall.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)

            Text(item.title)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textPrimary)
                .lineLimit(2)

            if item.priceVnd > 0 {
                Text(FeedPriceFormat.format(item.priceVnd))
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
            }

            HStack(spacing: 6) {
                if item.hasRealBadge {
                    Text(L10n.outfitSetItemRealBadge)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                if item.hasExploreBoost {
                    Text(L10n.outfitSetItemBoost)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        }
        .padding(10)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
    }
}

enum OutfitSlotLabels {
    static func label(for role: String) -> String {
        switch role.lowercased() {
        case "top": return L10n.outfitSlotTop
        case "bottom": return L10n.outfitSlotBottom
        case "shoes": return L10n.outfitSlotShoes
        case "dress": return L10n.outfitSlotDress
        case "outer": return L10n.outfitSlotOuter
        case "bag", "accessory": return L10n.outfitSlotBag
        default: return L10n.outfitSlotItem
        }
    }
}
