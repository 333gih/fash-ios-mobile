import SwiftUI

struct EditListingScreen: View {
    var listingId: String = ""
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.editListingSave, onDismiss: onDismiss) {
            Text(listingId).padding()
        }
    }
}
