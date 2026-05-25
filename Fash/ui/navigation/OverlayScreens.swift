import SwiftUI

/// Shared chrome for full-screen overlays (back button + title).
struct OverlayScreenHost<Content: View>: View {
    let title: String
    var onDismiss: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        FashScreenScaffold(title: title, showBack: true, onBack: onDismiss, content: content)
    }
}

struct HomeDeliveringScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(
            title: AppEnvironment.shippingEnabled ? L10n.homeDeliveringScreenTitle : L10n.homeDeliveringComingSoonTitle,
            onDismiss: onDismiss,
        ) {
            Text(AppEnvironment.shippingEnabled ? L10n.homeDeliveringListIntro : L10n.homeDeliveringComingSoonBody)
                .padding()
        }
    }
}
