import SwiftUI

/// Top row + progress for post steps — mirrors Android [CreateListingFlowHeader].
struct CreateListingFlowHeader: View {
    @Environment(\.fashSpacing) private var spacing
    let step: Int
    var showBack: Bool = true
    var centerTitle: String? = nil
    var showStepCaptionUnderTitle: Bool = false
    var showPrimaryAction: Bool = true
    let canProceed: Bool
    var nextBlockedReason: String? = nil
    let isSubmitting: Bool
    let onBack: () -> Void
    let onClose: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: spacing.spacing2) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 0) {
                    if showBack {
                        FashBackButton(action: onBack)
                    }
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FashColors.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                centerColumn
                    .frame(maxWidth: .infinity)

                Group {
                    if showPrimaryAction {
                        nextPill
                    } else {
                        Color.clear.frame(width: 72, height: 36)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            OnboardingProgressBar(step: step, total: totalPostSteps)
            if let nextBlockedReason, !canProceed, !nextBlockedReason.isEmpty {
                Text(nextBlockedReason)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.error)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, spacing.spacing3)
            }
        }
        .padding(.horizontal, spacing.spacing1)
        .padding(.bottom, spacing.spacing2)
    }

    @ViewBuilder
    private var centerColumn: some View {
        if let centerTitle {
            VStack(spacing: 2) {
                Text(centerTitle)
                    .font(FashTypography.titleMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if showStepCaptionUnderTitle {
                    Text(L10n.createListingStep(step, totalPostSteps))
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        } else {
            Text(L10n.createListingStep(step, totalPostSteps))
                .font(FashTypography.titleMedium.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    private var nextPill: some View {
        Button(action: onNext) {
            Group {
                if isSubmitting {
                    ProgressView()
                        .tint(FashColors.readableOnBrandPrimary)
                } else {
                    Text(step == totalPostSteps ? L10n.createListingPostForSale : L10n.createListingNext)
                        .font(FashTypography.labelLarge.weight(.bold))
                }
            }
            .foregroundStyle(canProceed ? FashColors.readableOnBrandPrimary : FashColors.textSecondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(canProceed ? FashColors.brandPrimary : FashColors.surfaceContainerHighest)
            .clipShape(Capsule())
        }
        .disabled(!canProceed || isSubmitting)
    }
}
