import SwiftUI

/// SwiftUI port of Android `PostPlaceholderScreen` (ui.main.tabs).
struct PostPlaceholderScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PostPlaceholderScreenBody()
    }
}

private struct PostPlaceholderScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "PostPlaceholderScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { PostPlaceholderScreen() }
}
