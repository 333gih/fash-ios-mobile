import SwiftUI

/// Step 6 — when this listing fits (season / climate / region).
struct CreateListingWearSeasonStep: View {
    @Bindable var postVM: PostViewModel

    var body: some View {
        PostStepScrollContent(bottomNotice: L10n.postHintWearSeason) {
            Text(L10n.postStepWearSeason)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
            Text(L10n.postStepWearSeasonSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)

            ListingWearSeasonEditor(
                yearRoundWear: postVM.draft.yearRoundWear,
                seasonKeys: postVM.draft.seasonKeys,
                climateZones: postVM.draft.climateZones,
                macroRegions: postVM.draft.macroRegions,
                enabled: true,
                onYearRoundToggle: { postVM.updateDraft { $0.yearRoundWear.toggle() } },
                onToggleSeason: { key in postVM.updateDraft { $0 = $0.toggleSeasonKey(key) } },
                onToggleClimate: { key in postVM.updateDraft { $0 = $0.toggleClimateZone(key) } },
                onToggleRegion: { key in postVM.updateDraft { $0 = $0.toggleMacroRegion(key) } }
            )
        }
        .background(PostListingColors.stepCanvas)
    }
}
