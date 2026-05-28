import SwiftUI

struct FashFilledButtonStyle: ButtonStyle {
    var enabledOpacity: CGFloat = 1
    var disabledOpacity: CGFloat = 0.4

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FashTypography.labelLarge.weight(.semibold))
            .foregroundStyle(FashColors.onBrandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                FashColors.brandPrimary.opacity(
                    configuration.isPressed ? 0.85 : enabledOpacity
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FashOutlinedBrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FashTypography.labelLarge.weight(.semibold))
            .foregroundStyle(FashColors.brandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(FashColors.brandPrimary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
