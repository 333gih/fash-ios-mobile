import SwiftUI

/// SwiftUI port of Android `NotificationScreen` (ui.main.tabs).
struct NotificationScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NotificationScreenBody()
    }
}

private struct NotificationScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "NotificationScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { NotificationScreen() }
}
