import SwiftUI

/// Promo carousel footer wrapper — Android [FashPromoSliderAdFooter].
struct FashPromoSliderAdFooterView: View {
    let slides: [FashPromoSlideDef]
    var onSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }

    var body: some View {
        FashPromoSliderView(slides: slides, onSlideClick: onSlideClick)
    }
}

enum FashPromoSliderAdFooter {
    static func slides(from response: AppAdvertisingSlidesResponse) -> [FashPromoSlideDef] {
        FashPromoSlider.slides(from: response)
    }
}
