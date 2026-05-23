import SwiftUI

struct OrdersScreen: View {
    var onDismiss: () -> Void
    var onSelectOrder: (String) -> Void

    var body: some View {
        FashScreenScaffold(title: L10n.ordersTitle, showBack: true, onBack: onDismiss) {
            Text(L10n.ordersTitle).padding()
        }
    }
}
