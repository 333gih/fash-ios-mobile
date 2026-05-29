import CoreGraphics

/// Shared promo carousel dimensions — Android `FashPromoCarouselCardHeight` / dock insets.
enum FashPromoMetrics {
    /// Standard card on Orders, Chat, Explore, Notifications, Profile seller.
    static let carouselHeight: CGFloat = 112
    /// Optional compact variant (legacy); Home/Orders use [carouselHeight] — Android `FashStickyPromoDockHeight`.
    static let compactCarouselHeight: CGFloat = 72
    /// Right strip width as fraction of card width when a banner image is shown.
    static let imageStripWidthFraction: CGFloat = 0.38

    static func cardHeight(compact: Bool) -> CGFloat {
        compact ? compactCarouselHeight : carouselHeight
    }

    /// Bottom dock inset above tab bar (divider + padding + card + dots).
    static func dockHeight(compact: Bool = false) -> CGFloat {
        let card = cardHeight(compact: compact)
        return 1 + 6 + card + 4 + 10
    }
}

/// Default dock for standard promo footer — Android `FashStickyPromoDockHeight`.
let FashStickyPromoDockHeight: CGFloat = FashPromoMetrics.dockHeight(compact: false)
``