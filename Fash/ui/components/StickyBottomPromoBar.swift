import SwiftUI

/// Bottom-docked promo chrome — Android [StickyBottomPromoBar].
struct StickyBottomPromoBar<Content: View>: View {
    var elevated: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(FashColors.outlineMuted.opacity(elevated ? 0.55 : 0.32))
            content()
        }
        .frame(maxWidth: .infinity)
        .background(FashColors.surfaceContainerLow)
        .shadow(color: elevated ? Color.black.opacity(0.12) : .clear, radius: elevated ? 10 : 0, y: elevated ? -2 : 0)
    }
}
