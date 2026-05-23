import SwiftUI

/// SwiftUI port of Android `ExploreListingPreviewSheet` (ui.explore).
struct ExploreListingPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ExploreListingPreviewSheetBody()
    }
}

private struct ExploreListingPreviewSheetBody: View {
    var body: some View {
        FashScreenScaffold(title: "ExploreListingPreviewSheet") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { ExploreListingPreviewSheet() }
}
