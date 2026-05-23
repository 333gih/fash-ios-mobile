import Foundation
import Observation

struct ExploreListingPreviewState: Identifiable {
    let id = UUID()
    let feedItem: ListingFeedItem
    let surface: String
    let gridPosition: Int
    var detail: ListingPreviewDetail?
    var isDetailLoading: Bool
}

@Observable
@MainActor
final class ListingPreviewStore {
    var state: ExploreListingPreviewState?
    private var loadTask: Task<Void, Never>?

    func open(
        item: ListingFeedItem,
        deps: AppDependencies,
        publicBrowse: Bool,
        surface: String = "explore",
        position: Int = 0,
    ) {
        loadTask?.cancel()
        state = ExploreListingPreviewState(
            feedItem: item,
            surface: surface,
            gridPosition: position,
            detail: nil,
            isDetailLoading: true,
        )
        let listingId = item.id
        loadTask = Task {
            let result = await deps.listingRepository.getListingPreviewDetail(
                listingId: listingId,
                publicBrowse: publicBrowse,
            )
            guard !Task.isCancelled else { return }
            switch result {
            case .success(let detail):
                guard var cur = state, cur.feedItem.id == listingId else { return }
                cur.detail = detail
                cur.isDetailLoading = false
                state = cur
            case .failure:
                guard var cur = state, cur.feedItem.id == listingId else { return }
                cur.isDetailLoading = false
                state = cur
            }
        }
    }

    func close() {
        loadTask?.cancel()
        loadTask = nil
        state = nil
    }
}
