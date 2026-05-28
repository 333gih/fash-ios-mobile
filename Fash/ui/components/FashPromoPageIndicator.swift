import SwiftUI

/// Pill page dots — Android [FashPromoPageIndicator].
struct FashPromoPageIndicator: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                let selected = index == currentPage
                Capsule()
                    .fill(selected ? FashColors.brandPrimary : FashColors.outlineMuted.opacity(0.7))
                    .frame(width: selected ? 18 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.22), value: currentPage)
            }
        }
    }
}
