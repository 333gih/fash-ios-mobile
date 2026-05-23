import Foundation

/// Port of Android `SellerProductPackageRepository` (data.sellerpackages).
final class SellerProductPackageRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
