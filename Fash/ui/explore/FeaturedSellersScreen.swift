import SwiftUI

struct FeaturedSellersScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.exploreFeaturedSellers, onDismiss: onDismiss) {
            Text(L10n.exploreFeaturedSellers).padding()
        }
    }
}
