import UIKit

/// Two-column waterfall layout — parity with Android `LazyVerticalStaggeredGrid` (shortest column).
final class ListingWaterfallLayout: UICollectionViewLayout {
    var columnCount = 2
    var columnSpacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    var sectionInset = UIEdgeInsets.zero
    /// `(itemIndex, columnWidth) -> tileHeight`
    var heightForItem: ((Int, CGFloat) -> CGFloat)?

    private var itemAttributes: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    override var collectionViewContentSize: CGSize {
        CGSize(width: collectionView?.bounds.width ?? 0, height: contentHeight)
    }

    override func prepare() {
        guard let collectionView else { return }
        itemAttributes.removeAll()

        let itemCount = collectionView.numberOfItems(inSection: 0)
        guard itemCount > 0 else {
            contentHeight = sectionInset.top + sectionInset.bottom
            return
        }

        let availableWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right
        guard availableWidth > 0 else {
            contentHeight = 0
            return
        }

        let columnWidth = (availableWidth - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount)
        var columnHeights = [CGFloat](repeating: sectionInset.top, count: columnCount)

        for item in 0..<itemCount {
            let indexPath = IndexPath(item: item, section: 0)
            let column = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let x = sectionInset.left + CGFloat(column) * (columnWidth + columnSpacing)
            let y = columnHeights[column]
            let height = max(1, heightForItem?(item, columnWidth) ?? columnWidth)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(x: x, y: y, width: columnWidth, height: height)
            itemAttributes.append(attributes)

            columnHeights[column] = y + height + rowSpacing
        }

        let maxColumn = columnHeights.max() ?? sectionInset.top
        contentHeight = max(maxColumn - rowSpacing, sectionInset.top) + sectionInset.bottom
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        itemAttributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        itemAttributes.first { $0.indexPath == indexPath }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else { return false }
        return newBounds.width != collectionView.bounds.width
    }
}
