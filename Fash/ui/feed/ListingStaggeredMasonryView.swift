import SwiftUI
import UIKit

/// Android `LazyVerticalStaggeredGrid` — embedded in `ScrollView` (`isScrollEnabled = false`).
struct ListingStaggeredMasonryView<Cell: View>: UIViewRepresentable {
    let items: [ListingFeedItem]
    var leadingInset: CGFloat?
    var trailingInset: CGFloat?
    var columnSpacing: CGFloat?
    var rowSpacing: CGFloat?
    var onLoadMore: (() -> Void)?
    var loadMoreTriggerDistance: Int = 3
    @Binding var contentHeight: CGFloat
    @ViewBuilder let cellContent: (ListingFeedItem, Int) -> Cell

    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight)
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = ListingWaterfallLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.alwaysBounceVertical = false
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.register(ListingMasonryHostingCell.self, forCellWithReuseIdentifier: ListingMasonryHostingCell.reuseId)
        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.applyLayout(to: collectionView)
        let signature = items.map(\.id)
        if context.coordinator.itemIds != signature {
            context.coordinator.itemIds = signature
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
        }
        DispatchQueue.main.async {
            context.coordinator.updateContentHeight(collectionView)
        }
    }

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        var parent: ListingStaggeredMasonryView<Cell>?
        var contentHeight: Binding<CGFloat>
        var itemIds: [String] = []

        init(contentHeight: Binding<CGFloat>) {
            self.contentHeight = contentHeight
        }

        func applyLayout(to collectionView: UICollectionView) {
            guard let parent, let layout = collectionView.collectionViewLayout as? ListingWaterfallLayout else { return }
            let spacing = FashSpacing()
            layout.columnCount = 2
            layout.columnSpacing = parent.columnSpacing ?? spacing.spacing2
            layout.rowSpacing = parent.rowSpacing ?? spacing.spacing2
            layout.sectionInset = UIEdgeInsets(
                top: 0,
                left: parent.leadingInset ?? spacing.editorialStart,
                bottom: 0,
                right: parent.trailingInset ?? spacing.editorialEnd
            )
            layout.heightForItem = { index, columnWidth in
                guard index < parent.items.count else { return columnWidth }
                let item = parent.items[index]
                let ratio = ListingMasonryGrid.staggerAspectRatio(for: item.id)
                return columnWidth / ratio
            }
        }

        func updateContentHeight(_ collectionView: UICollectionView) {
            collectionView.layoutIfNeeded()
            let height = collectionView.collectionViewLayout.collectionViewContentSize.height
            if abs(contentHeight.wrappedValue - height) > 0.5 {
                contentHeight.wrappedValue = height
            }
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            parent?.items.count ?? 0
        }

        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ListingMasonryHostingCell.reuseId,
                for: indexPath
            ) as! ListingMasonryHostingCell
            if let parent {
                let item = parent.items[indexPath.item]
                cell.setHostedContent(parent.cellContent(item, indexPath.item))
            }
            return cell
        }

        func collectionView(
            _ collectionView: UICollectionView,
            willDisplay cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath
        ) {
            guard let parent else { return }
            let count = parent.items.count
            guard count > 0, let onLoadMore = parent.onLoadMore else { return }
            let trigger = max(0, count - parent.loadMoreTriggerDistance)
            if indexPath.item >= trigger {
                onLoadMore()
            }
        }
    }
}

private final class ListingMasonryHostingCell: UICollectionViewCell {
    static let reuseId = "ListingMasonryHostingCell"

    func setHostedContent<Content: View>(_ content: Content) {
        contentConfiguration = UIHostingConfiguration {
            content
        }
        .margins(.all, 0)
    }
}
