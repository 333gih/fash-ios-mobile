import SwiftUI

/// Shared wear-season chips for create (step 6) and edit listing.
struct ListingWearSeasonEditor: View {
    @Environment(\.fashSpacing) private var spacing
    let yearRoundWear: Bool
    let seasonKeys: Set<String>
    let climateZones: Set<String>
    let macroRegions: Set<String>
    let enabled: Bool
    let onYearRoundToggle: () -> Void
    let onToggleSeason: (String) -> Void
    let onToggleClimate: (String) -> Void
    let onToggleRegion: (String) -> Void

    private var localeVi: Bool { AppLocale.currentTag != AppLocale.tagEN }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Toggle(isOn: Binding(get: { yearRoundWear }, set: { _ in onYearRoundToggle() })) {
                Text(L10n.postWearYearRound)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textPrimary)
            }
            .tint(FashColors.brandPrimary)
            .disabled(!enabled)

            chipSection(title: L10n.postWearSeasonKeys, options: ListingWearSeason.seasonOptions, onTap: onToggleSeason, selected: seasonKeys)
            chipSection(title: L10n.postWearClimateZones, options: ListingWearSeason.climateZoneOptions, onTap: onToggleClimate, selected: climateZones)
            chipSection(title: L10n.postWearMacroRegions, options: ListingWearSeason.macroRegionOptions, onTap: onToggleRegion, selected: macroRegions)
        }
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
                        guard enabled else { return }
                        onTap(opt.id)
                    } label: {
                        Text(opt.label(localeVi: localeVi))
                            .font(FashTypography.labelMedium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSel ? FashColors.onBrandPrimary : FashColors.textPrimary)
                            .background(isSel ? FashColors.brandPrimary : FashColors.surfaceContainerHigh)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                }
            }
        }
    }
}
