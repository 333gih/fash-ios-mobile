import SwiftUI

/// SwiftUI port of Android `ExploreOverlayHost` (ui.explore).
struct ExploreOverlayHost: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ExploreOverlayHostBody()
    }
}

private struct ExploreOverlayHostBody: View {
    var body: some View {
        FashScreenScaffold(title: "ExploreOverlayHost") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { ExploreOverlayHost() }
}
