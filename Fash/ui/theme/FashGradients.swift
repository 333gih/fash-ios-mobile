import SwiftUI

/// Primary CTA gradient — Android [FashGradients].
enum FashGradients {
    static func primaryCta(in size: CGSize) -> LinearGradient {
        LinearGradient(
            colors: [FashColors.brandPrimary, FashColorTokens.LightEditorial.brandPrimaryDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
