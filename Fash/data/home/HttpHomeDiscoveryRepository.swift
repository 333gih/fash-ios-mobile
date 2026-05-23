import Foundation

/// Port of Android `HttpHomeDiscoveryRepository` (data.home).
final class HttpHomeDiscoveryRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
