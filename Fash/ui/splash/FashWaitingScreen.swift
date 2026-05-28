import SwiftUI

struct FashWaitingScreen: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            FashBrandMarkText(
                text: L10n.splashWordmark,
                style: FashBrandTypography.markSplashCenter
            )
            Text(L10n.waitingScreenHeadline)
                .font(FashTypography.headlineMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(FashColors.textPrimary)
                .padding(.horizontal, 32)
            Text(L10n.waitingScreenStillLoading)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            ProgressView()
                .tint(FashColors.brandPrimary)
            Spacer()
            Text(L10n.splashFooterGenZ)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
        .padding()
        .background(FashColors.screen)
    }
}
