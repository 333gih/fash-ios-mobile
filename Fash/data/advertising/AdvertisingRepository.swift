import Foundation

/// Port of Android `AdvertisingRepository` (data.advertising).
final class AdvertisingRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
