import SwiftUI

/// SwiftUI port of Android `FeaturedSellersScreen` (ui.explore).
struct FeaturedSellersScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FeaturedSellersScreenBody()
    }
}

private struct FeaturedSellersScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "FeaturedSellersScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { FeaturedSellersScreen() }
}
