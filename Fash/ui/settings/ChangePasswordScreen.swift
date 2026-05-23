import SwiftUI

/// SwiftUI port of Android `ChangePasswordScreen` (ui.settings).
struct ChangePasswordScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ChangePasswordScreenBody()
    }
}

private struct ChangePasswordScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "ChangePasswordScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { ChangePasswordScreen() }
}
