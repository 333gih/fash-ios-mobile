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
    /// Keeps overlay in tree briefly while dismissing (navigation runs in parallel).
    private(set) var isDismissing = false

    var isOverlayVisible: Bool { state != nil || isDismissing }

    private var loadTask: Task<Void, Never>?
    private var previewContext: (listingId: String, surface: String, position: Int, openedAt: Date)?

    func open(
        item: ListingFeedItem,
        deps: AppDependencies,
        publicBrowse: Bool,
        surface: String = "explore",
        position: Int = 0
    ) {
        loadTask?.cancel()
        previewContext = (item.id, surface, position, Date())
        state = ExploreListingPreviewState(
            feedItem: item,
            surface: surface,
            gridPosition: position,
            detail: nil,
            isDetailLoading: true
        )
        let listingId = item.id
        loadTask = Task {
            let result = await deps.listingRepository.getListingPreviewDetail(
                listingId: listingId,
                publicBrowse: publicBrowse
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

    func close(deps: AppDependencies? = nil, animated: Bool = false) {
        guard state != nil || isDismissing else { return }
        if animated {
            isDismissing = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(280))
                finishClose(deps: deps)
            }
        } else {
            finishClose(deps: deps)
        }
    }

    private func finishClose(deps: AppDependencies?) {
        if let deps, let ctx = previewContext {
            let dwellMs = Int(Date().timeIntervalSince(ctx.openedAt) * 1_000)
            deps.feedEventReporter.previewDismiss(
                listingId: ctx.listingId,
                surface: ctx.surface,
                position: ctx.position,
                dwellMs: dwellMs
            )
        }
        previewContext = nil
        loadTask?.cancel()
        loadTask = nil
        state = nil
        isDismissing = false
    }

    func openDetail(deps: AppDependencies) {
        guard let preview = state else { return }
        deps.feedEventReporter.previewDetail(
            listingId: preview.feedItem.id,
            surface: preview.surface,
            position: preview.gridPosition
        )
    }
}
