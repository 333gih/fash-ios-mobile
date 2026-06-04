import SwiftUI

struct OnboardingScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: OnboardingViewModel
    var onStepComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: L10n.onboardingTitle,
                displayProgressStep: viewModel.uiProgressStep,
                progressTotal: viewModel.progressTotalSteps,
                onBack: { _ = viewModel.goBack(deps: deps) }
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.onboardingQuestion)
                        .font(FashTypography.headlineSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                    Text(L10n.onboardingSubtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(FashColors.brandPrimary)
                            .frame(maxWidth: .infinity, minHeight: 160)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.tags) { tag in
                                PostSelectablePill(
                                    text: tag.displayLabel(),
                                    selected: viewModel.selectedIds.contains(tag.id)
                                ) {
                                    viewModel.toggleSelection(tag)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            HStack {
                Text(L10n.onboardingSelectedCount(viewModel.selectedIds.count, 3))
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                Spacer()
                Button(L10n.onboardingSkip) {
                    viewModel.skipAestheticTagsPersistLocal(deps: deps, onSuccess: onStepComplete)
                }
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            FashPrimaryButton(
                title: L10n.onboardingContinue,
                isLoading: viewModel.isSubmitting,
                enabled: !viewModel.isSubmitting
            ) {
                viewModel.submitAestheticTagsPut(deps: deps, onSuccess: onStepComplete)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(FashColors.screen)
        .task {
            if viewModel.tags.isEmpty {
                viewModel.loadTags(deps: deps)
            }
        }
    }
}
