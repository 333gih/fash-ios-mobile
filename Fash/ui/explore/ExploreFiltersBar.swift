import SwiftUI

/// Filter summary card — Android [ExploreFiltersBar].
struct ExploreFiltersBar: View {
    @Environment(\.fashSpacing) private var spacing
    let hasActiveFilters: Bool
    let filterSummaryParts: [String]
    let isSearchMode: Bool
    let onOpenFilters: () -> Void
    var onClearFilters: (() -> Void)?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
        HStack(alignment: .top, spacing: 8) {
            Button(action: onOpenFilters) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.exploreFiltersBarTitle)
                            .font(FashTypography.titleSmall.weight(.semibold))
                            .foregroundStyle(FashColors.textPrimary)
                        if !filterSummaryParts.isEmpty {
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
                        } else {
                            Text(isSearchMode
                                 ? L10n.exploreFiltersBarSubtitleActive
                                 : L10n.exploreFiltersBarSubtitleIdle)
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            if hasActiveFilters, let onClearFilters {
                Button(L10n.exploreFiltersClear, action: onClearFilters)
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.brandPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(FashColors.surfaceContainerLow)
        .clipShape(shape)
        .padding(.horizontal, spacing.editorialStart)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}
