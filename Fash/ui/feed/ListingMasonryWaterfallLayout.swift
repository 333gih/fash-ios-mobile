import SwiftUI

/// Shortest-column masonry — parity with Android `LazyVerticalStaggeredGrid`.
struct ListingMasonryWaterfallLayout: Layout {
    var columns: Int = 2
    var columnSpacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    var leadingInset: CGFloat = 24
    var trailingInset: CGFloat = 16

    struct Cache {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var totalSize: CGSize = .zero
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        cache = computeLayout(proposal: proposal, subviews: subviews)
        return cache.totalSize
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        if cache.positions.count != subviews.count {
            cache = computeLayout(proposal: proposal, subviews: subviews)
        }
        for (index, subview) in subviews.enumerated() where index < cache.positions.count {
            let origin = cache.positions[index]
            let size = cache.sizes[index]
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> Cache {
        guard let width = proposal.width, width > 0, columns > 0, !subviews.isEmpty else {
            return Cache(totalSize: CGSize(width: proposal.width ?? 0, height: 0))
        }

        let available = max(0, width - leadingInset - trailingInset)
        let columnWidth = (available - CGFloat(columns - 1) * columnSpacing) / CGFloat(columns)
        guard columnWidth > 0 else {
            return Cache(totalSize: CGSize(width: width, height: 0))
        }

        var columnYs = [CGFloat](repeating: 0, count: columns)
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        positions.reserveCapacity(subviews.count)
        sizes.reserveCapacity(subviews.count)

        for subview in subviews {
            let column = columnYs.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let x = leadingInset + CGFloat(column) * (columnWidth + columnSpacing)
            let y = columnYs[column]
            let measured = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let height = max(1, measured.height)
            let size = CGSize(width: columnWidth, height: height)

            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            columnYs[column] = y + height + rowSpacing
        }

        let maxY = columnYs.max() ?? 0
        let height = max(0, maxY - rowSpacing)
        return Cache(positions: positions, sizes: sizes, totalSize: CGSize(width: width, height: height))
    }
}
