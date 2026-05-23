import SwiftUI

struct InviteFriendsScreen: View {
    var onDismiss: () -> Void

    var body: some View {
        FashScreenScaffold(title: L10n.profileInviteFriendsTitle, showBack: true, onBack: onDismiss) {
            Text(L10n.profileInviteFriendsSubtitle).padding()
        }
    }
}
