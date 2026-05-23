import SwiftUI

/// SwiftUI port of Android `EditListingScreen` (ui.listing).
struct EditListingScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        EditListingScreenBody()
    }
}

private struct EditListingScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "EditListingScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { EditListingScreen() }
}
