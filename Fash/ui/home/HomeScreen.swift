import SwiftUI

/// SwiftUI port of Android `HomeScreen` (ui.home).
struct HomeScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HomeScreenBody()
    }
}

private struct HomeScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "HomeScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { HomeScreen() }
}
