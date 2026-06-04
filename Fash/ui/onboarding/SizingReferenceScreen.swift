import SwiftUI

struct SizingReferenceScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: OnboardingViewModel
    var onStepComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: L10n.onboardingSizingScreenTitle,
                displayProgressStep: viewModel.uiProgressStep,
                progressTotal: viewModel.progressTotalSteps,
                onBack: { _ = viewModel.goBack(deps: deps) }
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.onboardingSizingRequiredHint)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)

                    Text(L10n.onboardingSizingOptionalBodyTitle)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    Text(L10n.onboardingSizingBodyFirstSubtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)

                    HStack(spacing: 12) {
                        PostListingOutlinedField(
                            label: L10n.onboardingSizingOptionalHeightLabel,
                            text: Binding(
                                get: { viewModel.heightCm },
                                set: { viewModel.onHeightCmChange($0) }
                            ),
                            keyboard: .numberPad
                        )
                        PostListingOutlinedField(
                            label: L10n.onboardingSizingOptionalWeightLabel,
                            text: Binding(
                                get: { viewModel.weightKg },
                                set: { viewModel.onWeightKgChange($0) }
                            ),
                            keyboard: .decimalPad
                        )
                    }

                    ReferenceSizePickerSection(
                        referenceSize: Binding(
                            get: { viewModel.referenceSize },
                            set: { viewModel.onReferenceSizeChange($0) }
                        ),
                        genderPreference: viewModel.genderPreference,
                        label: L10n.profileSetupReferenceSizeLabel
                    )

                    Text(L10n.profileSetupMeasurementUnit)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    HStack(spacing: 8) {
                        PostSelectablePill(text: L10n.postUnitCm, selected: viewModel.measurementUnit == "cm") {
                            viewModel.onMeasurementUnitChange("cm")
                        }
                        PostSelectablePill(text: L10n.postUnitIn, selected: viewModel.measurementUnit == "in") {
                            viewModel.onMeasurementUnitChange("in")
                        }
                    }

                    Text(L10n.profileSetupMeasurementsOptional)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    measurementGrid
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            HStack {
                Spacer()
                Button(L10n.onboardingSkip) {
                    viewModel.skipSizingPersistLocal(deps: deps, onSuccess: onStepComplete)
                }
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            FashPrimaryButton(
                title: L10n.onboardingContinue,
                isLoading: viewModel.isSubmitting,
                enabled: viewModel.canSubmitSizing() && !viewModel.isSubmitting
            ) {
                viewModel.submitSizingOnly(deps: deps, onSuccess: onStepComplete)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(FashColors.screen)
    }

    private var measurementGrid: some View {
        VStack(spacing: 12) {
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementChest,
                text: Binding(get: { viewModel.measurementChest }, set: { viewModel.onMeasurementChestChange($0) }),
                keyboard: .decimalPad
            )
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementHem,
                text: Binding(get: { viewModel.measurementHem }, set: { viewModel.onMeasurementHemChange($0) }),
                keyboard: .decimalPad
            )
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementLength,
                text: Binding(get: { viewModel.measurementLength }, set: { viewModel.onMeasurementLengthChange($0) }),
                keyboard: .decimalPad
            )
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementShoulders,
                text: Binding(get: { viewModel.measurementShoulders }, set: { viewModel.onMeasurementShouldersChange($0) }),
                keyboard: .decimalPad
            )
            PostListingOutlinedField(
                label: L10n.profileSetupMeasurementSleeve,
                text: Binding(get: { viewModel.measurementSleeve }, set: { viewModel.onMeasurementSleeveChange($0) }),
                keyboard: .decimalPad
            )
        }
    }
}
