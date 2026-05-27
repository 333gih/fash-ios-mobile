import SwiftUI

/// Shimmer + ambient shadow — Android [FashModifiers].
struct FashShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        colors: [
                            FashColors.surfaceContainerHigh.opacity(0.55),
                            FashColors.surfaceContainerHighest.opacity(0.85),
                            FashColors.surfaceContainerHigh.opacity(0.55),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w * 0.75)
                    .offset(x: (w * 1.75) * phase - w * 0.75)
                    .onAppear {
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
                .clipped()
            }
    }
}

extension View {
    func fashShimmer() -> some View {
        modifier(FashShimmerModifier())
    }
}
