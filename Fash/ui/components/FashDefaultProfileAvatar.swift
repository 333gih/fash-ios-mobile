import SwiftUI

/// Brand default avatar when no profile photo — Android `FashDefaultProfileAvatar`.
struct FashDefaultProfileAvatar: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(FashColors.brandPrimary)
                    .frame(width: size * 0.88, height: size * 0.88)
                Text("F")
                    .font(.system(size: size * 0.44, weight: .bold, design: .default))
                    .italic()
                    .foregroundStyle(FashColors.onBrandPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
