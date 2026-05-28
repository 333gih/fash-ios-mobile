import Foundation
import Observation

@Observable
@MainActor
final class HomeEditorialListViewModel {
    private let repository: EditorialGuideRepository

    var loading = true
    var loadingMore = false
    var error = false
    var posts: [HomeEditorialPostStub] = []

    private var offset = 0
    private var hasMore = true

    init(repository: EditorialGuideRepository = AppDependencies.shared.editorialGuideRepository) {
        self.repository = repository
    }

    func loadInitial() async {
        offset = 0
        hasMore = true
        loading = true
        error = false
        let result = await repository.listAll(limit: 20, offset: 0)
        loading = false
        switch result {
        case .success(let page):
            posts = page.items
            hasMore = page.hasMore
            offset = page.items.count
        case .failure:
            posts = []
            error = true
        }
    }

    func loadMoreIfNeeded(currentIndex: Int) async {
        guard hasMore, !loadingMore, !loading, !posts.isEmpty else { return }
        guard currentIndex >= posts.count - 3 else { return }
        loadingMore = true
        let result = await repository.listAll(limit: 20, offset: offset)
        loadingMore = false
        if case .success(let page) = result, !page.items.isEmpty {
            posts.append(contentsOf: page.items)
            offset += page.items.count
            hasMore = page.hasMore
        } else if case .success(let page) = result {
            hasMore = page.hasMore
        }
    }
}
