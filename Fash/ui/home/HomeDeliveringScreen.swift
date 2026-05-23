import SwiftUI

/// SwiftUI port of Android `HomeDeliveringScreen` (ui.home).
struct HomeDeliveringScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HomeDeliveringScreenBody()
    }
}

private struct HomeDeliveringScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "HomeDeliveringScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { HomeDeliveringScreen() }
}
