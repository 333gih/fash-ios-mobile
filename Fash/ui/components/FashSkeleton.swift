import SwiftUI

/// Shimmer placeholders — Android [FashSkeleton].
enum FashSkeleton {
    static func box(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(FashColors.surfaceVariant.opacity(0.55))
            .frame(width: width, height: height)
            .fashShimmer()
    }

    /// 2-column grid matching Home/Explore loading.
    static func listingGrid(columns: Int = 2, rows: Int = 4) -> some View {
        let spacing = FashSpacing()
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing.spacing2), count: columns),
            spacing: spacing.spacing3
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                listingCardPlaceholder
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, spacing.spacing4)
    }

    private static var listingCardPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            box(height: 180, cornerRadius: 16)
            box(height: 12)
            box(height: 12, width: 80)
            box(height: 14, width: 64)
        }
    }
}
