import SwiftUI

/// Empty state — Android [FashEmptyState].
struct FashEmptyStateView: View {
    let title: String
    var subtitle: String?
    var systemImage: String = "tray"
    var actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(FashColors.brandPrimary.opacity(0.10))
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.system(size: 36))
                        .foregroundStyle(FashColors.brandPrimary)
                }
            Text(title)
                .font(FashTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundStyle(FashColors.textPrimary)
                .multilineTextAlignment(.center)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let onAction {
                Button(actionTitle, action: onAction)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}
