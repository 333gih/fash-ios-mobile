import Foundation

/// Port of Android `UserShippingAddressRepository` (data.address).
final class UserShippingAddressRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
