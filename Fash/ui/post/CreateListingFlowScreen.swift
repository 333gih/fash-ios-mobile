import SwiftUI

/// SwiftUI port of Android `CreateListingFlowScreen` (ui.post).
struct CreateListingFlowScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CreateListingFlowScreenBody()
    }
}

private struct CreateListingFlowScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "CreateListingFlowScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { CreateListingFlowScreen() }
}
