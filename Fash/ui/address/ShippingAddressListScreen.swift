import SwiftUI

/// SwiftUI port of Android `ShippingAddressListScreen` (ui.address).
struct ShippingAddressListScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ShippingAddressListScreenBody()
    }
}

private struct ShippingAddressListScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "ShippingAddressListScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { ShippingAddressListScreen() }
}
