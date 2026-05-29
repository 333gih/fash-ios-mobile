import SwiftUI

/// Compact filter row under sticky tabs — Android [ExploreStickyFilterRow].
struct ExploreStickyFilterRow: View {
    @Environment(\.fashSpacing) private var spacing
    let hasActiveFilters: Bool
    let filterSummaryParts: [String]
    let onOpenFilters: () -> Void
    var onClearFilters: (() -> Void)?

    private var summaryCompact: String {
        switch filterSummaryParts.count {
        case 0:
            return L10n.exploreFilterSummaryDefault
        case 1:
            return filterSummaryParts[0]
        default:
            return "\(filterSummaryParts[0]) · +\(filterSummaryParts.count - 1)"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: spacing.spacing3) {
            Button(action: onOpenFilters) {
                HStack(alignment: .center, spacing: spacing.spacing3) {
                    ZStack(alignment: .topTrailing) {
                        ExploreFilterIconPulse(active: hasActiveFilters) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(FashColors.brandPrimary)
                                .frame(width: 40, height: 40)
                                .background(FashColors.brandPrimary.opacity(0.14))
                                .clipShape(Circle())
                        }
                        if hasActiveFilters, !filterSummaryParts.isEmpty {
                            Text("\(min(filterSummaryParts.count, 99))")
                                .font(FashTypography.labelSmall)
                                .foregroundStyle(FashColors.onBrandPrimary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(FashColors.brandPrimary)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.exploreFiltersBarTitle)
                            .font(FashTypography.titleSmall.weight(.semibold))
                            .foregroundStyle(FashColors.textPrimary)
                        if hasActiveFilters {
                            Text(summaryCompact)
                                .font(FashTypography.bodyMedium.weight(.medium))
                                .foregroundStyle(FashColors.textPrimary)
                                .lineLimit(1)
                        } else {
                            ExploreFilterIdleTeaser(compact: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.exploreFiltersToggleCd)

            trailingAction
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, spacing.spacing3)
        .background(FashColors.surfaceContainerLow)
    }

    @ViewBuilder
    private var trailingAction: some View {
        if hasActiveFilters, let onClearFilters {
            Button(action: onClearFilters) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel(L10n.exploreFiltersClearCd)
        }
    }
}
