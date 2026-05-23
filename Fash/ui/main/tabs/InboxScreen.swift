import SwiftUI

/// SwiftUI port of Android `InboxScreen` (ui.main.tabs).
struct InboxScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        InboxScreenBody()
    }
}

private struct InboxScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "InboxScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { InboxScreen() }
}
