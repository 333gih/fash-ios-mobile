import SwiftUI

struct ShoppingPreferencesOnboardScreen: View {
    @Environment(AppDependencies.self) private var deps
    var onContinue: () -> Void = {}

    @State private var buySelected = true
    @State private var sellSelected = false
    @State private var selectedGender = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingProgressBar(step: 2, total: 6)
            Text(L10n.onboardingShoppingTitle)
                .font(FashTypography.headlineMedium)
                .foregroundStyle(FashColors.textPrimary)
            Text(L10n.onboardingShoppingSubtitle)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            HStack(spacing: 8) {
                PostSelectablePill(
                    text: L10n.onboardingShoppingIntentBuy,
                    selected: buySelected
                ) { buySelected.toggle() }
                PostSelectablePill(
                    text: L10n.onboardingShoppingIntentSell,
                    selected: sellSelected
                ) { sellSelected.toggle() }
            }
            Text(L10n.onboardingShoppingGenderTitle)
                .font(FashTypography.titleSmall)
                .foregroundStyle(FashColors.textPrimary)
            Text(L10n.onboardingShoppingGenderSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            HStack(spacing: 8) {
                genderPill("women", L10n.onboardingShoppingGenderWomen)
                genderPill("men", L10n.onboardingShoppingGenderMen)
            }
            HStack(spacing: 8) {
                genderPill("non_binary", L10n.onboardingShoppingGenderNonBinary)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.error)
            }
            Spacer()
            FashPrimaryButton(
                title: L10n.onboardingContinue,
                isLoading: isSubmitting,
                enabled: (buySelected || sellSelected) && !isSubmitting,
                action: submit
            )
        }
        .padding(24)
        .background(FashColors.screen)
    }

    @ViewBuilder
    private func genderPill(_ value: String, _ label: String) -> some View {
        PostSelectablePill(text: label, selected: selectedGender == value) {
            selectedGender = selectedGender == value ? "" : value
        }
    }

    private func submit() {
        guard buySelected || sellSelected else { return }
        var intents: [String] = []
        if buySelected { intents.append("buy") }
        if sellSelected { intents.append("sell") }
        let gender = selectedGender.trimmingCharacters(in: .whitespaces).lowercased()
        isSubmitting = true
        errorMessage = nil
        Task {
            let result = await deps.userRepository.saveShoppingPreferences(
                shoppingIntents: intents,
                gender: gender.isEmpty ? nil : gender
            )
            await MainActor.run {
                isSubmitting = false
                switch result {
                case .success:
                    onContinue()
                case .failure(let err):
                    errorMessage = FashErrorPresentation.userMessage(for: err)
                }
            }
        }
    }
}
