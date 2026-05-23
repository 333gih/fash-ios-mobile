import SwiftUI

struct OnboardingProgressBar: View {
    let step: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(FashColors.outlineMuted.opacity(0.35))
                Capsule()
                    .fill(FashColors.brandPrimary)
                    .frame(width: geo.size.width * CGFloat(step) / CGFloat(max(total, 1)))
            }
        }
        .frame(height: 4)
    }
}
