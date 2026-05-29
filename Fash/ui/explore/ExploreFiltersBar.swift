import SwiftUI

/// Filter summary card — Android [ExploreFiltersBar].
struct ExploreFiltersBar: View {
    @Environment(\.fashSpacing) private var spacing
    let hasActiveFilters: Bool
    let filterSummaryParts: [String]
    var compact: Bool = false
    let onOpenFilters: () -> Void
    var onClearFilters: (() -> Void)?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
        HStack(alignment: .top, spacing: 4) {
            Button(action: onOpenFilters) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack(alignment: .topTrailing) {
                        ExploreFilterIconPulse(active: hasActiveFilters) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(FashColors.brandPrimary)
                                .frame(width: 28, height: 28)
                        }
                        if hasActiveFilters, !filterSummaryParts.isEmpty {
                            Text("\(min(filterSummaryParts.count, 99))")
                                .font(FashTypography.labelSmall)
                                .foregroundStyle(FashColors.onBrandPrimary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(FashColors.brandPrimary)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.exploreFiltersBarTitle)
                            .font(FashTypography.titleSmall.weight(.semibold))
                            .foregroundStyle(FashColors.textPrimary)
                        if !filterSummaryParts.isEmpty {
                            summaryChips
                        } else {
                            ExploreFilterIdleTeaser(compact: compact)
                                .padding(.top, compact ? 2 : 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            trailingAction
        }
        .padding(.horizontal, 12)
        .padding(.vertical, compact ? 8 : 12)
        .background(FashColors.surfaceContainerLow)
        .clipShape(shape)
        .padding(.horizontal, spacing.editorialStart)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var summaryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(filterSummaryParts.enumerated()), id: \.offset) { _, part in
                    Text(part)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.brandPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(FashColors.brandPrimary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 6)
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
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FashColors.brandPrimary.opacity(0.9))
                .frame(width: 28, height: 40)
                .allowsHitTesting(false)
        }
    }
}
