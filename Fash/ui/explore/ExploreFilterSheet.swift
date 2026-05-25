import SwiftUI

/// SwiftUI port of Android `ExploreFilterSheet` (ui.explore).
struct ExploreFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ExploreFilterSheetBody()
    }
}

private struct ExploreFilterSheetBody: View {
    var body: some View {
        FashScreenScaffold(title: "ExploreFilterSheet") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { ExploreFilterSheet() }
}
