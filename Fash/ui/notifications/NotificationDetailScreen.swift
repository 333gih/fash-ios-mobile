import SwiftUI

/// SwiftUI port of Android `NotificationDetailScreen` (ui.notifications).
struct NotificationDetailScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NotificationDetailScreenBody()
    }
}

private struct NotificationDetailScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "NotificationDetailScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { NotificationDetailScreen() }
}
