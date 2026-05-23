import SwiftUI

/// SwiftUI port of Android `SettingsScreen` (ui.main.tabs).
struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SettingsScreenBody()
    }
}

private struct SettingsScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "SettingsScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { SettingsScreen() }
}
