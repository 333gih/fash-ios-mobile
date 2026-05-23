import SwiftUI

/// SwiftUI port of Android `AppFeatureTourOverlay` (ui.onboarding).
struct AppFeatureTourOverlay: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppFeatureTourOverlayBody()
    }
}

private struct AppFeatureTourOverlayBody: View {
    var body: some View {
        FashScreenScaffold(title: "AppFeatureTourOverlay") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { AppFeatureTourOverlay() }
}
