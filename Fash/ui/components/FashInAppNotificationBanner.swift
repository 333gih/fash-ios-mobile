import SwiftUI

struct FashInAppNotificationBanner: View {
    let session: FashInAppNotificationSession
    var onTap: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.textPrimary)
                    Text(session.body)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FashColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .task {
            try? await Task.sleep(for: .milliseconds(4_500))
            onDismiss()
        }
    }
}
