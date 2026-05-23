import SwiftUI

/// Shared onboarding step chrome (Android onboarding flow).
struct OnboardingStepShell: View {
    let title: String
    let bodyText: String
    let actionTitle: String
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingProgressBar(step: 1, total: 6)
            Text(title)
                .font(FashTypography.headlineMedium)
                .foregroundStyle(FashColors.textPrimary)
            Text(bodyText)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            Spacer()
            FashPrimaryButton(title: actionTitle, action: onContinue)
        }
        .padding(24)
        .background(FashColors.screen)
    }
}
