import SwiftUI

struct HomeEditorialListScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.homeEditorialListTitle, onDismiss: onDismiss) {
            Text(L10n.homeEditorialListSubtitle).padding()
        }
    }
}
