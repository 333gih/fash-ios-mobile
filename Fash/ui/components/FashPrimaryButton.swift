import SwiftUI

/// Primary CTA — Android [FashPrimaryButton] (48pt, gradient, radius 12).
struct FashPrimaryButton: View {
    let title: String
    var isLoading = false
    var showsArrow = false
    var cornerRadius: CGFloat = 12
    var height: CGFloat = 48
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FashGradients.primaryCta(in: CGSize(width: 320, height: height)))
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(title)
                            .font(FashTypography.labelLarge.weight(.bold))
                            .foregroundStyle(FashColors.readableOnBrandPrimary)
                        if showsArrow {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(FashColors.readableOnBrandPrimary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .disabled(isLoading || !enabled)
        .opacity(enabled ? 1 : 0.55)
        .buttonStyle(.plain)
    }
}
