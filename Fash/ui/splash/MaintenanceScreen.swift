import SwiftUI

struct MaintenanceScreen: View {
    let title: String
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [FashColors.brandPrimary.opacity(0.14), FashColors.screen],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 260)
                .overlay(alignment: .bottom) {
                    MaintenanceMascotImage(maxWidth: 190)
                        .padding(.bottom, 4)
                }

                VStack(spacing: 14) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(.body)
                        .foregroundStyle(FashColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Text(L10n.maintenanceSessionSafe)
                        .font(.caption)
                        .foregroundStyle(FashColors.textSecondary.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .padding(.top, 12)

                FashPrimaryButton(title: L10n.maintenanceRetry, action: onRetry)
                    .padding(.horizontal, 40)
                    .padding(.top, 28)
                    .padding(.bottom, 36)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FashColors.screen)
    }
}
