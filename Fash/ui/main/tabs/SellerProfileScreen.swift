import SwiftUI

struct SellerProfileScreen: View {
    let username: String
    var onDismiss: () -> Void

    var body: some View {
        FashScreenScaffold(title: "@\(username)", showBack: true, onBack: onDismiss) {
            Text(L10n.navProfile)
                .padding()
        }
    }
}
