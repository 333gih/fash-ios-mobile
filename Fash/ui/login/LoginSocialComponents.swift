import SwiftUI

struct LoginOrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(FashColors.outlineMuted.opacity(0.7))
                .frame(height: 1)
            Text(L10n.loginOrContinue)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary.opacity(0.85))
            Rectangle()
                .fill(FashColors.outlineMuted.opacity(0.7))
                .frame(height: 1)
        }
    }
}

struct LoginSocialOutlineButton: View {
    let icon: AnyView
    let label: String
    var enabled = true
    var dimmed = false
    let action: () -> Void

    private let spacing = FashSpacing()

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                icon
                    .frame(width: 48)
                Text(label)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(maxWidth: .infinity)
                Color.clear.frame(width: 48, height: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: spacing.buttonHeight)
            .background(FashColors.surfaceContainerHighest)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.52), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(dimmed ? 0.55 : 1)
    }
}

struct GoogleBrandIcon: View {
    var body: some View {
        Image("ic_brand_google")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
    }
}
