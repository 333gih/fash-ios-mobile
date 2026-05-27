import SwiftUI

/// Be Vietnam Pro typography — Android Type.kt + Material 3 scale.
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
        if name.contains("Medium") { return .medium }
        return .regular
    }

    static let displayLarge = font("BeVietnamPro-Bold", size: 56, relativeTo: .largeTitle)
    static let headlineSmall = font("BeVietnamPro-SemiBold", size: 24, relativeTo: .title)
    static let titleLarge = font("BeVietnamPro-SemiBold", size: 22, relativeTo: .title2)
    static let titleMedium = font("BeVietnamPro-SemiBold", size: 16, relativeTo: .title3)
    static let titleSmall = font("BeVietnamPro-SemiBold", size: 14, relativeTo: .callout)
    static let bodyLarge = font("BeVietnamPro-Regular", size: 16, relativeTo: .body)
    static let bodyMedium = font("BeVietnamPro-Regular", size: 14, relativeTo: .subheadline)
    static let bodySmall = font("BeVietnamPro-Regular", size: 12, relativeTo: .caption)
    static let labelLarge = font("BeVietnamPro-SemiBold", size: 14, relativeTo: .callout)
    static let labelMedium = font("BeVietnamPro-Medium", size: 12, relativeTo: .caption)
    static let labelSmall = font("BeVietnamPro-Medium", size: 11, relativeTo: .caption2)

    // Legacy alias
    static let headlineMedium = headlineSmall
}

/// Additional tokens — Android [FashTextStyles].
enum FashTextStyles {
    static let price = Font.custom("BeVietnamPro-Bold", size: 22)
    static let displayMediumEditorial = Font.custom("BeVietnamPro-Bold", size: 45)
}
