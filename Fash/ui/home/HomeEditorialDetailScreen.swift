import SwiftUI

/// SwiftUI port of Android `HomeEditorialDetailScreen` (ui.home).
struct HomeEditorialDetailScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HomeEditorialDetailScreenBody()
    }
}

private struct HomeEditorialDetailScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "HomeEditorialDetailScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { HomeEditorialDetailScreen() }
}
