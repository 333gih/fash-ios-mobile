import SwiftUI

struct ShoppingPreferencesOnboardScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: OnboardingViewModel
    var onStepComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingStepHeader(
                title: L10n.onboardingShoppingTitle,
                displayProgressStep: viewModel.uiProgressStep,
                progressTotal: viewModel.progressTotalSteps,
                onBack: { _ = viewModel.goBack(deps: deps) }
            )
            Text(L10n.onboardingShoppingSubtitle)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .padding(.horizontal, 24)
            HStack(spacing: 8) {
                PostSelectablePill(
                    text: L10n.onboardingShoppingIntentBuy,
                    selected: viewModel.shoppingBuy
                ) { viewModel.toggleShoppingBuy() }
                PostSelectablePill(
                    text: L10n.onboardingShoppingIntentSell,
                    selected: viewModel.shoppingSell
                ) { viewModel.toggleShoppingSell() }
            }
            .padding(.horizontal, 24)
            Text(L10n.onboardingShoppingGenderTitle)
                .font(FashTypography.titleSmall)
                .foregroundStyle(FashColors.textPrimary)
                .padding(.horizontal, 24)
            Text(L10n.onboardingShoppingGenderSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
                .padding(.horizontal, 24)
            HStack(spacing: 8) {
                genderPill("women", L10n.onboardingShoppingGenderWomen)
                genderPill("men", L10n.onboardingShoppingGenderMen)
            }
            .padding(.horizontal, 24)
            HStack(spacing: 8) {
                genderPill("non_binary", L10n.onboardingShoppingGenderNonBinary)
            }
            .padding(.horizontal, 24)
            Spacer()
            FashPrimaryButton(
                title: L10n.onboardingContinue,
                isLoading: viewModel.isSubmitting,
                enabled: (viewModel.shoppingBuy || viewModel.shoppingSell) && !viewModel.isSubmitting
            ) {
                viewModel.submitShoppingPreferences(deps: deps, onSuccess: onStepComplete)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(FashColors.screen)
    }

    @ViewBuilder
    private func genderPill(_ value: String, _ label: String) -> some View {
        PostSelectablePill(text: label, selected: viewModel.genderPreference == value) {
            viewModel.setGenderPreference(viewModel.genderPreference == value ? "" : value)
        }
    }
}
