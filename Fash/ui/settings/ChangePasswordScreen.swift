import SwiftUI

struct ChangePasswordScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.settingsRowChangePassword, onDismiss: onDismiss) {
            Text(L10n.settingsRowChangePassword).padding()
        }
    }
}
