import SwiftUI

struct NotificationDetailScreen: View {
    let notificationId: String
    var onDismiss: () -> Void

    var body: some View {
        FashScreenScaffold(title: L10n.notificationDetailTitle, showBack: true, onBack: onDismiss) {
            Text(notificationId).padding()
        }
    }
}
