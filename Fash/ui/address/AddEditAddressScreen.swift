import SwiftUI

/// SwiftUI port of Android `AddEditAddressScreen` (ui.address).
struct AddEditAddressScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AddEditAddressScreenBody()
    }
}

private struct AddEditAddressScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "AddEditAddressScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { AddEditAddressScreen() }
}
