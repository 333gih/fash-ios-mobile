import SwiftUI

/// Space reserved above bottom nav / tab bar for sticky promo slider.
let FashStickyPromoDockHeight: CGFloat = 128

/// Bottom-docked promo chrome — Android `StickyBottomPromoBar`.
struct StickyBottomPromoBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.35)
            content()
        }
        .frame(maxWidth: .infinity)
        .background(FashColors.surfaceContainerLow)
    }
}
