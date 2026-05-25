import SwiftUI

struct SellerProductPackagesScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.sellerPackagesScreenTitle, onDismiss: onDismiss) {
            Text(L10n.sellerPackagesScreenSubtitle).padding()
        }
    }
}
