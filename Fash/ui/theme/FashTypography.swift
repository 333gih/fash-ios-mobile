import SwiftUI

/// Be Vietnam Pro typography (Android Type.kt). Add .ttf files under Fash/Resources/Fonts/.
enum FashTypography {
    private static func font(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size, relativeTo: style)
        }
        return .system(size: size, weight: weightFor(name), design: .default)
    }

    private static func weightFor(_ name: String) -> Font.Weight {
        if name.contains("Bold") { return .bold }
        if name.contains("SemiBold") { return .semibold }
        return .regular
    }

    static let displayLarge = font("BeVietnamPro-Bold", size: 34, relativeTo: .largeTitle)
    static let headlineMedium = font("BeVietnamPro-SemiBold", size: 20, relativeTo: .headline)
    static let titleMedium = font("BeVietnamPro-SemiBold", size: 16, relativeTo: .title3)
    static let bodyLarge = font("BeVietnamPro-Regular", size: 16, relativeTo: .body)
    static let bodyMedium = font("BeVietnamPro-Regular", size: 14, relativeTo: .subheadline)
    static let labelLarge = font("BeVietnamPro-SemiBold", size: 14, relativeTo: .callout)
}
