import SwiftUI

/// Profile sizing (letter chips + unit + optional measurements) — Android `ProfileSetupSizingSection`.
struct ProfileSetupSizingSection: View {
    @Binding var referenceSize: String
    @Binding var measurementUnit: String
    @Binding var measurementHem: String
    @Binding var measurementChest: String
    @Binding var measurementLength: String
    @Binding var measurementShoulders: String
    @Binding var measurementSleeve: String
    var genderPreference: String
    var compactDensity: Bool = false
    var showTitle: Bool = true
    var showSubtitle: Bool = true

    private var sectionSpacing: CGFloat { compactDensity ? 10 : 16 }
    private var fieldSpacing: CGFloat { compactDensity ? 8 : 12 }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            if showTitle {
                Text(L10n.profileSetupSizingTitle)
                    .font(compactDensity ? FashTypography.titleSmall.weight(.semibold) : FashTypography.titleMedium.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
            }
            if showSubtitle {
                Text(L10n.profileSetupSizingSubtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }

            ReferenceSizePickerSection(
                referenceSize: $referenceSize,
                genderPreference: genderPreference,
                label: L10n.profileSetupReferenceSizeLabel
            )

            Text(L10n.profileSetupMeasurementUnit)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            HStack(spacing: 8) {
                PostSelectablePill(text: L10n.postUnitCm, selected: measurementUnit == "cm") {
                    measurementUnit = "cm"
                }
                PostSelectablePill(text: L10n.postUnitIn, selected: measurementUnit == "in") {
                    measurementUnit = "in"
                }
            }

            Text(L10n.profileSetupMeasurementsOptional)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            measurementFields
        }
    }

    private var measurementFields: some View {
        VStack(spacing: fieldSpacing) {
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementChest,
                text: $measurementChest,
                keyboard: .decimalPad
            )
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementHem,
                text: $measurementHem,
                keyboard: .decimalPad
            )
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementLength,
                text: $measurementLength,
                keyboard: .decimalPad
            )
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementShoulders,
                text: $measurementShoulders,
                keyboard: .decimalPad
            )
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementSleeve,
                text: $measurementSleeve,
                keyboard: .decimalPad
            )
        }
    }
}
