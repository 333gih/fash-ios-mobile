import SwiftUI

/// Shared onboarding step chrome (Android onboarding flow).
struct OnboardingStepShell: View {
    let step: Int
    let total: Int
    let title: String
    let bodyText: String
    let actionTitle: String
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingProgressBar(step: step, total: total)
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
