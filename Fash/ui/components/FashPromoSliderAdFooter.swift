import SwiftUI

/// Promo carousel footer — Android `FashPromoSliderAdFooter` (Orders / Notifications).
struct FashPromoSliderAdFooterView: View {
    let slides: [FashPromoSlideDef]
    var onSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }

    var body: some View {
        StickyBottomPromoBar {
            FashPromoSliderView(slides: slides, onSlideClick: onSlideClick)
        }
    }
}

enum FashPromoSliderAdFooter {
    static func slides(from response: AppAdvertisingSlidesResponse) -> [FashPromoSlideDef] {
        FashPromoSlider.slides(from: response)
    }
}
