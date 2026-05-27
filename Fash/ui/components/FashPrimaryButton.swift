import SwiftUI

/// Primary CTA — Android [FashPrimaryButton] (48pt, gradient, radius 12).
struct FashPrimaryButton: View {
    let title: String
    var isLoading = false
    var cornerRadius: CGFloat = 12
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FashGradients.primaryCta(in: CGSize(width: 320, height: 48)))
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(title)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}
