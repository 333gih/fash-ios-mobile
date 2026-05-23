import SwiftUI

struct SetupGateRetryScreen: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.setupGateErrorTitle)
                .font(FashTypography.headlineMedium)
            Text(L10n.setupGateErrorBody)
                .font(FashTypography.bodyMedium)
                .multilineTextAlignment(.center)
            FashPrimaryButton(title: L10n.setupGateRetry, action: onRetry)
        }
        .padding(32)
    }
}
