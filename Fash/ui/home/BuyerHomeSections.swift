import SwiftUI

struct HomeBrandFooterStrip: View {
    @Environment(\.fashSpacing) private var spacing
    var includeHorizontalEdgePadding: Bool = true

    var body: some View {
        let edgeStart = includeHorizontalEdgePadding ? spacing.editorialStart : 0
        let edgeEnd = includeHorizontalEdgePadding ? spacing.editorialEnd : 0
        VStack(spacing: 6) {
            Divider()
                .overlay(FashColors.outlineMuted.opacity(0.35))
                .padding(.bottom, 20)
            Text(L10n.homeBrandFooterSub)
                .fashBrandMarkStyle(FashBrandTypography.marketplaceSubtitle)
                .foregroundStyle(FashColors.textSecondary.opacity(0.85))
                .multilineTextAlignment(.center)
            FashBrandMarkText(
                text: L10n.homeBrandMarketplace,
                style: FashBrandTypography.markBoldItalicSmall
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, edgeStart)
        .padding(.trailing, edgeEnd)
        .padding(.top, 36)
        .padding(.bottom, 40)
    }
}

struct HomeSizingBanner: View {
    @Environment(\.fashSpacing) private var spacing
    var onAddSizeClick: () -> Void
    var onDismiss: () -> Void
    var includeHorizontalEdgePadding: Bool = true

    var body: some View {
        let edgeStart = includeHorizontalEdgePadding ? spacing.editorialStart : 0
        let edgeEnd = includeHorizontalEdgePadding ? spacing.editorialEnd : 0
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.homeSizingBannerTitle)
                    .font(FashTypography.titleSmall.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                Text(L10n.homeSizingBannerBody)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                Button(L10n.homeSizingBannerCta, action: onAddSizeClick)
                    .buttonStyle(.bordered)
                    .tint(FashColors.brandPrimary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FashColors.textSecondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.homeSizingBannerDismissCd)
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .padding(.vertical, 12)
        .background(FashColors.brandPrimary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
        .padding(.leading, edgeStart)
        .padding(.trailing, edgeEnd)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}

struct BuyerHomeJourneyCompactBar: View {
    @Environment(\.fashSpacing) private var spacing
    let stats: BuyerHomeStats
    var onDeliveringClick: () -> Void
    var onSavedClick: () -> Void
    var onInReviewClick: () -> Void
    var includeHorizontalEdgePadding: Bool = true

    var body: some View {
        let edgeStart = includeHorizontalEdgePadding ? spacing.editorialStart : 0
        let edgeEnd = includeHorizontalEdgePadding ? spacing.editorialEnd : 0
        HStack(spacing: 8) {
            journeyChip(
                icon: "shippingbox.fill",
                label: L10n.homeJourneyDelivering,
                value: formatJourneyCount(stats.activeDeliveryOrders),
                action: onDeliveringClick
            )
            journeyChip(
                icon: "bookmark",
                label: L10n.homeJourneySaved,
                value: formatJourneyCount(stats.savedListingsCount),
                action: onSavedClick
            )
            journeyChip(
                icon: "doc.text.magnifyingglass",
                label: L10n.homeJourneyInReview,
                value: formatJourneyCount(stats.listingsInReviewCount),
                action: onInReviewClick
            )
        }
        .padding(.leading, edgeStart)
        .padding(.trailing, edgeEnd)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private func journeyChip(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(FashColors.brandPrimary)
                VStack(alignment: .leading, spacing: 0) {
                    Text(label)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(1)
                    Text(value)
                        .font(FashTypography.labelLarge.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(FashColors.surfaceContainerHigh)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func formatJourneyCount(_ n: Int) -> String {
        if n > 99 { return "99+" }
        if n < 0 { return "0" }
        return "\(n)"
    }
}

struct HomeExploreShortcutBanner: View {
    @Environment(\.fashSpacing) private var spacing
    let shortcut: HomeExploreShortcut
    var onClick: () -> Void
    var includeHorizontalEdgePadding: Bool = true

    var body: some View {
        let edgeStart = includeHorizontalEdgePadding ? spacing.editorialStart : 0
        let edgeEnd = includeHorizontalEdgePadding ? spacing.editorialEnd : 0
        let title = shortcut.labelKey == "home_explore_shortcut_category"
            ? L10n.homeExploreShortcutCategory
            : L10n.homeExploreShortcutStyle
        let detail = shortcut.aestheticTagName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? shortcut.aestheticTagId?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        Button(action: onClick) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundStyle(FashColors.brandPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FashTypography.labelLarge.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                    if let detail {
                        Text(detail)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(L10n.homeExploreShortcutAction)
                    .font(FashTypography.labelMedium.weight(.bold))
                    .foregroundStyle(FashColors.brandPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(FashColors.surfaceVariant.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.leading, edgeStart)
        .padding(.trailing, edgeEnd)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
