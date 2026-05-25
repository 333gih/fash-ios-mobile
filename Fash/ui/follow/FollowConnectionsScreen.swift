import SwiftUI

struct FollowConnectionsScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.profileFollowers, onDismiss: onDismiss) {
            Text(L10n.profileFollowing).padding()
        }
    }
}
