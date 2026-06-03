import SwiftUI

/// Step 6 — when this listing fits (season / climate / region).
struct CreateListingWearSeasonStep: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var postVM: PostViewModel

    private var localeVi: Bool { AppLocale.currentTag != AppLocale.tagEN }

    var body: some View {
        PostStepScrollContent(bottomNotice: L10n.postHintWearSeason) {
            Text(L10n.postStepWearSeason)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
            Text(L10n.postStepWearSeasonSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)

            wearToggleRow(
                title: L10n.postWearYearRound,
                isOn: postVM.draft.yearRoundWear,
                onToggle: { postVM.updateDraft { $0.yearRoundWear.toggle() } }
            )

            chipSection(title: L10n.postWearSeasonKeys, options: ListingWearSeason.seasonOptions) { key in
                postVM.updateDraft { $0 = $0.toggleSeasonKey(key) }
            } selected: postVM.draft.seasonKeys

            chipSection(title: L10n.postWearClimateZones, options: ListingWearSeason.climateZoneOptions) { key in
                postVM.updateDraft { $0 = $0.toggleClimateZone(key) }
            } selected: postVM.draft.climateZones

            chipSection(title: L10n.postWearMacroRegions, options: ListingWearSeason.macroRegionOptions) { key in
                postVM.updateDraft { $0 = $0.toggleMacroRegion(key) }
            } selected: postVM.draft.macroRegions
        }
        .background(PostListingColors.stepCanvas)
    }

    @ViewBuilder
    private func wearToggleRow(title: String, isOn: Bool, onToggle: @escaping () -> Void) -> some View {
        Toggle(isOn: Binding(get: { isOn }, set: { _ in onToggle() })) {
            Text(title)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary)
        }
        .tint(FashColors.brandPrimary)
    }

    @ViewBuilder
    private func chipSection(
        title: String,
        options: [ListingWearSeason.Option],
        onTap: @escaping (String) -> Void,
        selected: Set<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            Text(title)
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.id) { opt in
                    let isSel = selected.contains(opt.id)
                    Button {
                        onTap(opt.id)
                    } label: {
                        Text(opt.label(localeVi: localeVi))
                            .font(FashTypography.labelMedium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSel ? FashColors.onBrand : FashColors.textPrimary)
                            .background(isSel ? FashColors.brandPrimary : FashColors.surfaceContainerHigh)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
