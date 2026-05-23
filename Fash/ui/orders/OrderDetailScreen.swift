import SwiftUI

struct OrderDetailScreen: View {
    let orderId: String
    var onDismiss: () -> Void

    var body: some View {
        FashScreenScaffold(title: L10n.orderDetailTitle, showBack: true, onBack: onDismiss) {
            Text(orderId).padding()
        }
    }
}
