import SwiftUI

/// SwiftUI port of Android `SellerProductPackagesScreen` (ui.sellerpackages).
struct SellerProductPackagesScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SellerProductPackagesScreenBody()
    }
}

private struct SellerProductPackagesScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "SellerProductPackagesScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { SellerProductPackagesScreen() }
}
