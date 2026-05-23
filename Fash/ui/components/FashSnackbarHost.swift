import SwiftUI

/// SwiftUI port of Android `FashSnackbarHost` (ui.components).
struct FashSnackbarHost: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FashSnackbarHostBody()
    }
}

private struct FashSnackbarHostBody: View {
    var body: some View {
        FashScreenScaffold(title: "FashSnackbarHost") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { FashSnackbarHost() }
}
