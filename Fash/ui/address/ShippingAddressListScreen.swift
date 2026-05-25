import SwiftUI

struct ShippingAddressListScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.addressListTitle, onDismiss: onDismiss) {
            Text(L10n.addressEmptyAlertBody).padding()
        }
    }
}
