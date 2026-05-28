import SwiftUI

/// Shimmer placeholders — Android [FashSkeleton].
enum FashSkeleton {
    static func box(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(FashColors.surfaceVariant.opacity(0.55))
            .frame(width: width, height: height)
            .fashShimmer()
    }

    /// 2-column masonry grid matching Home/Explore loading.
    static func listingGrid(columns: Int = 2, rows: Int = 4, staggered: Bool = true) -> some View {
        let spacing = FashSpacing()
        let ratios: [CGFloat] = [3.0 / 4.0, 4.0 / 5.0, 5.0 / 6.0]
        return VStack(spacing: spacing.spacing3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing.spacing2) {
                    listingCardPlaceholder(
                        aspectRatio: staggered ? ratios[row % ratios.count] : 4.0 / 5.0
                    )
                    listingCardPlaceholder(
                        aspectRatio: staggered ? ratios[(row + 1) % ratios.count] : 4.0 / 5.0
                    )
                }
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, spacing.spacing4)
    }

    private static func listingCardPlaceholder(aspectRatio: CGFloat = 4.0 / 5.0) -> some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 6) {
                box(height: geo.size.width / aspectRatio, cornerRadius: 16)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}
