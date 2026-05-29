import SwiftUI

/// Android `Modifier.listingCardMarquee()` — `basicMarquee(900ms, 1200ms, 35.dp)`.
enum ListingCardMarquee {
    static let initialDelayMs: UInt64 = 900
    static let repeatDelayMs: UInt64 = 1_200
    static let velocity: CGFloat = 35
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
