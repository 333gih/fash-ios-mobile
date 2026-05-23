import SwiftUI

/// SwiftUI port of Android `FollowConnectionsScreen` (ui.follow).
struct FollowConnectionsScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FollowConnectionsScreenBody()
    }
}

private struct FollowConnectionsScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "FollowConnectionsScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { FollowConnectionsScreen() }
}
