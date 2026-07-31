import SwiftUI

/// Android `Modifier.listingCardMarquee()` — optimized for performance.
enum ListingCardMarquee {
    static let initialDelayMs: UInt64 = 2_000  // Increased from 900ms to reduce animation churn
    static let repeatDelayMs: UInt64 = 2_000   // Increased from 1200ms to reduce frequency
    static let velocity: CGFloat = 30          // Slightly slower for smoother animation
}

/// Single-line marquee for listing grid footers (title, seller, condition, secondary meta).
struct ListingCardMarqueeText: View {
    let text: String
    var font: Font = FashTypography.bodySmall
    var fontWeight: Font.Weight = .regular
    var color: Color = .white
    var lineHeight: CGFloat = 16

    var body: some View {
        FashMarqueeText(
            text: text,
            font: font,
            fontWeight: fontWeight,
            color: color,
            lineHeight: lineHeight,
            initialDelayMs: ListingCardMarquee.initialDelayMs,
            repeatDelayMs: ListingCardMarquee.repeatDelayMs,
            velocity: ListingCardMarquee.velocity
        )
    }
}
