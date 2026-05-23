import Foundation

/// Port of Android `HomeDiscoveryRepository` (data.home).
final class HomeDiscoveryRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
