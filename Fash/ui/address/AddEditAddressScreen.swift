import SwiftUI

struct AddEditAddressScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.addressAddTitle, onDismiss: onDismiss) {
            Text(L10n.addressConfirm).padding()
        }
    }
}
