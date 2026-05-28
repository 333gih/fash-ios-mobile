import Foundation
import Observation

@Observable
@MainActor
final class HomeEditorialDetailViewModel {
    private let repository: EditorialGuideRepository

    var loading = true
    var error = false
    var guide: EditorialGuideDetail?

    init(repository: EditorialGuideRepository = AppDependencies.shared.editorialGuideRepository) {
        self.repository = repository
    }

    func load(slug: String) async {
        loading = true
        error = false
        guide = nil
        let result = await repository.getBySlug(slug)
        loading = false
        switch result {
        case .success(let detail):
            guide = detail
        case .failure:
            error = true
        }
    }
}
