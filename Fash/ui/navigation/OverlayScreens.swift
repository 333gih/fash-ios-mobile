import SwiftUI

/// Shared chrome for full-screen overlays (back button + title).
struct OverlayScreenHost<Content: View, Trailing: View>: View {
    let title: String
    var onDismiss: () -> Void
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) where Trailing == EmptyView {
        self.title = title
        self.onDismiss = onDismiss
        self.trailing = { EmptyView() }
        self.content = content
    }

    init(
        title: String,
        onDismiss: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.onDismiss = onDismiss
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        FashScreenScaffold(
            title: title,
            showBack: true,
            onBack: onDismiss,
            trailing: trailing,
            content: content
        )
    }
}

struct HomeDeliveringScreen: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(
            title: AppEnvironment.shippingEnabled ? L10n.homeDeliveringScreenTitle : L10n.homeDeliveringComingSoonTitle,
            onDismiss: onDismiss
        ) {
            Text(AppEnvironment.shippingEnabled ? L10n.homeDeliveringListIntro : L10n.homeDeliveringComingSoonBody)
                .padding()
        }
    }
}
