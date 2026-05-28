import Foundation
import Observation

@Observable
@MainActor
final class SellerProductPackagesViewModel {
    private let repository: SellerProductPackageRepository

    var packages: [SellerProductPackage] = []
    var isLoading = true
    var loadError: String?

    init(repository: SellerProductPackageRepository = AppDependencies.shared.sellerProductPackageRepository) {
        self.repository = repository
    }

    func refresh() async {
        isLoading = true
        loadError = nil
        let result = await repository.listPackages(activeOnly: true)
        isLoading = false
        switch result {
        case .success(let res):
            packages = res.packages
        case .failure(let err):
            packages = []
            loadError = FashErrorPresentation.userMessage(for: err)
        }
    }
}
