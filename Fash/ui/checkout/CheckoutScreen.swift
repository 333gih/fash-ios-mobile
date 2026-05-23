import SwiftUI

struct CheckoutScreen: View {
    let listingId: String
    var onDismiss: () -> Void

    var body: some View {
        FashScreenScaffold(title: L10n.checkoutTitle, showBack: true, onBack: onDismiss) {
            Text(listingId).padding()
        }
    }
}
