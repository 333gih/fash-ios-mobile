import SwiftUI

/// Shared onboarding chrome: back, title, progress — Android onboarding header row.
struct OnboardingStepHeader: View {
    let title: String
    let displayProgressStep: Int
    let progressTotal: Int
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(width: 44, height: 44)
                }
                Text(title)
                    .font(FashTypography.titleMedium.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                Color.clear.frame(width: 44, height: 44)
            }
            OnboardingProgressBar(step: displayProgressStep, total: progressTotal)
                .padding(.horizontal, 4)
        }
    }
}
