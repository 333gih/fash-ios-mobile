import SwiftUI

/// SwiftUI port of Android `GuestLoginSheet` (ui.guest).
struct GuestLoginSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GuestLoginSheetBody()
    }
}

private struct GuestLoginSheetBody: View {
    var body: some View {
        FashScreenScaffold(title: "GuestLoginSheet") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { GuestLoginSheet() }
}
