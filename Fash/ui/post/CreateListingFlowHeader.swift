import SwiftUI

struct CreateListingFlowHeader: View {
    @Environment(\.fashSpacing) private var spacing
    let step: Int
    let canProceed: Bool
    let isSubmitting: Bool
    let onBack: () -> Void
    let onClose: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: spacing.spacing2) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(FashColors.textPrimary)
                }
                Spacer()
                if step > 0 {
                    Text(L10n.createListingStep(step, totalPostSteps))
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundStyle(FashColors.textPrimary)
                }
            }
            if step > 0 {
                ProgressView(value: Double(step), total: Double(totalPostSteps))
                    .tint(FashColors.brandPrimary)
            }
            if step > 0, step < totalPostSteps {
                FashPrimaryButton(title: L10n.createListingNext, isLoading: isSubmitting, action: onNext)
                    .disabled(!canProceed || isSubmitting)
                    .opacity(canProceed ? 1 : 0.5)
            } else if step == totalPostSteps {
                FashPrimaryButton(title: L10n.createListingPostForSale, isLoading: isSubmitting, action: onNext)
                    .disabled(!canProceed || isSubmitting)
                    .opacity(canProceed ? 1 : 0.5)
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, spacing.spacing3)
        .background(FashColors.surfaceContainerHighest)
    }
}
