import SwiftUI

/// Brand wordmark styles — Android [FashBrandTypography].
/// iOS custom fonts do not synthesize italic; [FashBrandMarkText] applies editorial skew.
enum FashBrandTypography {
    struct MarkStyle: Equatable {
        let fontName: String
        let size: CGFloat
        let tracking: CGFloat
        /// Horizontal shear for synthesized italic (Android `FontStyle.Italic`).
        let italicShear: CGFloat

        var font: Font {
            if UIFont(name: fontName, size: size) != nil {
                return .custom(fontName, size: size)
            }
            return .system(size: size, weight: .bold)
        }

        var italicTransform: CGAffineTransform {
            CGAffineTransform(a: 1, b: 0, c: italicShear, d: 1, tx: 0, ty: 0)
        }
    }

    static let markBoldItalic = MarkStyle(
        fontName: "BeVietnamPro-Bold",
        size: 22,
        tracking: 0.8,
        italicShear: -0.21
    )

    static let markBoldItalicMedium = MarkStyle(
        fontName: "BeVietnamPro-Bold",
        size: 18,
        tracking: 0.8,
        italicShear: -0.21
    )

    static let markBoldItalicLarge = MarkStyle(
        fontName: "BeVietnamPro-Bold",
        size: 34,
        tracking: 1,
        italicShear: -0.21
    )

    static let markBoldItalicSmall = MarkStyle(
        fontName: "BeVietnamPro-Bold",
        size: 12,
        tracking: 1.2,
        italicShear: -0.21
    )

    static let markSplashCenter = MarkStyle(
        fontName: "BeVietnamPro-Bold",
        size: 52,
        tracking: -0.5,
        italicShear: -0.21
    )

    static let marketplaceSubtitle = MarkStyle(
        fontName: "BeVietnamPro-Bold",
        size: 10,
        tracking: 2,
        italicShear: -0.21
    )
}

extension View {
    /// Applies brand mark italic skew + tracking — use for any standalone brand line.
    func fashBrandMarkStyle(_ style: FashBrandTypography.MarkStyle) -> some View {
        font(style.font)
            .tracking(style.tracking)
            .transformEffect(style.italicTransform)
    }
}
