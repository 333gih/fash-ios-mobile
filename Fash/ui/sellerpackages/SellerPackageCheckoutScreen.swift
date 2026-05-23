import SwiftUI

/// SwiftUI port of Android `SellerPackageCheckoutScreen` (ui.sellerpackages).
struct SellerPackageCheckoutScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SellerPackageCheckoutScreenBody()
    }
}

private struct SellerPackageCheckoutScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "SellerPackageCheckoutScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { SellerPackageCheckoutScreen() }
}
