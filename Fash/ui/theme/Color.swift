import SwiftUI

/// Semantic colors for SwiftUI (Android [FashColors]).
enum FashColors {
    static var brandPrimary: Color { FashColorTokens.LightEditorial.brandPrimary }
    static var screen: Color {
        FashThemeState.shared.isDark
            ? FashColorTokens.Dark.screen
            : (FashThemeState.shared.lightAppearance == .pureWhite
                ? FashColorTokens.LightPureWhite.screen
                : FashColorTokens.LightEditorial.screen)
    }
    static var textPrimary: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.textPrimary : FashColorTokens.LightEditorial.textPrimary
    }
    static var textSecondary: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.textSecondary : FashColorTokens.LightEditorial.textSecondary
    }
    static var surfaceContainer: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.surfaceContainer : FashColorTokens.LightEditorial.surfaceContainer
    }
    static var surfaceContainerHigh: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.surfaceContainerHigh : FashColorTokens.LightEditorial.surfaceContainerHigh
    }
    static var surfaceContainerHighest: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.surfaceContainerHighest : FashColorTokens.LightEditorial.surfaceContainerHighest
    }
    static var surfaceVariant: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.surfaceContainer : FashColorTokens.LightEditorial.surfaceVariant
    }
    static var outlineMuted: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.outlineMuted : FashColorTokens.LightEditorial.outlineMuted
    }
    static var error: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.error : FashColorTokens.LightEditorial.error
    }
}

@Observable
final class FashThemeState {
    static let shared = FashThemeState()
    var isDark = false
    var lightAppearance: FashLightAppearance = .editorial
}

enum FashLightAppearance {
    case editorial
    case pureWhite
}
