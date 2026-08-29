import SwiftUI

struct DailyOutfitDropListScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    let initialSets: [OutfitSetCard]
    var onDismiss: () -> Void
    var onSetClick: (OutfitSetCard) -> Void

    @State private var sets: [OutfitSetCard] = []
    @State private var loading = false
    @State private var loadError = false

    var body: some View {
        FashScreenScaffold(
            title: L10n.homeSectionDailyOutfitDropTitle,
            showBack: true,
            onBack: onDismiss
        ) {
            Group {
                if loading && sets.isEmpty {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if loadError && sets.isEmpty {
                    FashEmptyStateView(
                        title: L10n.feedLoadError,
                        systemImage: "exclamationmark.triangle"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sets.isEmpty {
                    FashEmptyStateView(
                        title: L10n.outfitDailyDropListEmpty,
                        systemImage: "hanger"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            Text(L10n.homeSectionDailyOutfitDropSubtitle)
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textSecondary)
                            ForEach(sets) { set in
                                OutfitSetListRow(set: set)
                                    .onTapGesture { onSetClick(set) }
                            }
                        }
                        .padding(.horizontal, spacing.editorialStart)
                        .padding(.vertical, spacing.spacing3)
                    }
                }
            }
            .background(FashColors.screen)
        }
        .task { await refresh() }
    }

    private func refresh() async {
        sets = initialSets
        loading = true
        loadError = false
        defer { loading = false }
        let result = await deps.recommendationRepository.fetchDailyOutfitDrop(limit: 24)
        switch result {
        case .success(let fetched) where !fetched.isEmpty:
            sets = fetched
        case .failure:
            if sets.isEmpty { loadError = true }
        default:
            break
        }
    }
}

private struct OutfitSetListRow: View {
    @Environment(\.fashSpacing) private var spacing
    let set: OutfitSetCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(set.title)
                .font(FashTypography.labelLarge.weight(.semibold))
                .lineLimit(2)
            if !set.reasonLabel.isEmpty {
                Text(set.reasonLabel)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            HStack(spacing: 6) {
                ForEach(set.items.prefix(4)) { item in
                    FashAsyncImage(url: item.coverImageUrl, contentMode: .fill)
                        .frame(width: 56, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin))
    }
}
