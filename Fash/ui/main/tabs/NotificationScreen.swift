import SwiftUI

struct NotificationScreen: View {
    var detailId: String?
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                if let detailId {
                    NotificationDetailScreen(notificationId: detailId, onDismiss: onDismiss)
                } else {
                    Text(L10n.notificationInboxUnavailableTitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
            .navigationTitle(L10n.notificationInboxUnavailableTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.dialogOk, action: onDismiss)
                }
            }
        }
    }
}
