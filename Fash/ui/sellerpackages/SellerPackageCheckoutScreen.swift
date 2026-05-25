import SwiftUI

struct SellerPackageCheckoutScreen: View {
    var packageId: String = ""
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.sellerPackagesCheckoutTitle, onDismiss: onDismiss) {
            Text(packageId).padding()
        }
    }
}
