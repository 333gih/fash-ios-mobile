import Foundation

/// Port of Android `AddressLocalStore` (data.address).
final class AddressLocalStore {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
