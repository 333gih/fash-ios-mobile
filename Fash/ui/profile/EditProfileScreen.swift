import SwiftUI

struct EditProfileScreen: View {
    var onDismiss: () -> Void

    var body: some View {
        FashScreenScaffold(title: L10n.editProfileTitle, showBack: true, onBack: onDismiss) {
            Text(L10n.editProfileTitle).padding()
        }
    }
}
