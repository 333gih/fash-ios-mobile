import SwiftUI
import UIKit

/// Semantic colors for SwiftUI (Android [FashColors]).
enum FashColors {
    static var brandPrimary: Color { FashColorTokens.LightEditorial.brandPrimary }
    static var brandSecondary: Color { FashColorTokens.LightEditorial.brandPrimaryDeep }
    static var onBrandPrimary: Color { FashColorTokens.LightEditorial.onBrandPrimary }
    static var screen: Color {
        FashThemeState.shared.isDark
            ? FashColorTokens.Dark.screen
            : (FashThemeState.shared.lightAppearance == .pureWhite
                ? FashColorTokens.LightPureWhite.screen
                : FashColorTokens.LightEditorial.screen)
    }
    /// Material `surface` — same canvas as [screen] (Android TopAppBar containerColor).
    static var surface: Color { screen }
    static var textPrimary: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.textPrimary : FashColorTokens.LightEditorial.textPrimary
    }
    static var textSecondary: Color {
        FashThemeState.shared.isDark ? FashColorTokens.Dark.textSecondary : FashColorTokens.LightEditorial.textSecondary
    }
    static var surfaceContainerLow: Color {
        if FashThemeState.shared.isDark { return FashColorTokens.Dark.surfaceContainerLow }
        return FashThemeState.shared.lightAppearance == .pureWhite
            ? FashColorTokens.LightPureWhite.surfaceContainerLow
            : FashColorTokens.LightEditorial.surfaceContainerLow
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

    /// Foreground readable on [brandPrimary] — Android [fashReadableOn].
    static var readableOnBrandPrimary: Color {
        FashColorTokens.LightEditorial.brandPrimary.fashReadableOn()
    }
}

extension Color {
    func fashReadableOn() -> Color {
        relativeLuminance > 0.5 ? FashColors.textPrimary : .white
    }

    private var relativeLuminance: Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lr = channel(Double(r)), lg = channel(Double(g)), lb = channel(Double(b))
        return 0.2126 * lr + 0.7152 * lg + 0.0722 * lb
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
