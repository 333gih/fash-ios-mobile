import SwiftUI

/// SwiftUI port of Android `ExploreSearchOverlay` (ui.explore).
struct ExploreSearchOverlay: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ExploreSearchOverlayBody()
    }
}

private struct ExploreSearchOverlayBody: View {
    var body: some View {
        FashScreenScaffold(title: "ExploreSearchOverlay") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { ExploreSearchOverlay() }
}
