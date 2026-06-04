import SwiftUI

/// Simplified scrim + card tour — Android [AppFeatureTourOverlay].
struct AppFeatureTourOverlay: View {
    let currentStep: AppTourStep
    var onStepChange: (AppTourStep) -> Void
    var onSkip: () -> Void
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
            VStack {
                Spacer()
                tourCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    private var tourCard: some View {
        let steps = AppTourStep.allCases
        let index = currentStep.rawValue
        let total = steps.count
        let progress = CGFloat(index + 1) / CGFloat(max(total, 1))

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.appTourChip)
                    .font(FashTypography.labelSmall.weight(.semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(FashColors.brandPrimary.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                Button(L10n.appTourSkip, action: onSkip)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
            }
            ProgressView(value: progress)
                .tint(FashColors.brandPrimary)
            Text(currentStep.title)
                .font(FashTypography.titleMedium.weight(.bold))
                .foregroundStyle(FashColors.textPrimary)
            Text(currentStep.body)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if currentStep != .intro {
                    Button(L10n.appTourBack) {
                        if let prev = AppTourStep(rawValue: currentStep.rawValue - 1) {
                            onStepChange(prev)
                        }
                    }
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
                }
                Spacer()
                Button(currentStep == steps.last ? L10n.appTourDone : L10n.appTourNext) {
                    if currentStep == steps.last {
                        onFinish()
                    } else if let next = AppTourStep(rawValue: currentStep.rawValue + 1) {
                        onStepChange(next)
                    }
                }
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
            }
        }
        .padding(20)
        .background(FashColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }
}

#Preview {
    FashTheme {
        AppFeatureTourOverlay(
            currentStep: .intro,
            onStepChange: { _ in },
            onSkip: {},
            onFinish: {}
        )
    }
}
