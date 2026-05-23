import SwiftUI

struct ChatDetailScreen: View {
    let conversationId: String
    var onDismiss: () -> Void

    var body: some View {
        FashScreenScaffold(title: L10n.navChat, showBack: true, onBack: onDismiss) {
            Text(conversationId).padding()
        }
    }
}
