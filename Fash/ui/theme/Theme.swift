import SwiftUI

/// Digital Editorial theme wrapper (Android [FashTheme]).
struct FashTheme<Content: View>: View {
    @Environment(\.colorScheme) private var systemScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let state = FashThemeState.shared
        state.isDark = AppThemePreference.shared.resolvedIsDark(systemDark: systemScheme == .dark)
        return content
            .environment(\.fashSpacing, FashSpacing())
            .tint(FashColors.brandPrimary)
            .background(FashColors.screen)
    }
}
