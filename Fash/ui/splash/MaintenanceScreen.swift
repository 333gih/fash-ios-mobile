import SwiftUI

struct MaintenanceScreen: View {
    let title: String
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            FashEmptyStateView(
                title: title,
                subtitle: message,
                systemImage: "wrench.and.screwdriver"
            )
            FashPrimaryButton(title: L10n.maintenanceRetry, action: onRetry)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FashColors.screen)
    }
}
