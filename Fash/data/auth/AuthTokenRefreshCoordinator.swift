import Foundation

/// Port of Android `AuthTokenRefreshCoordinator` (data.auth).
final class AuthTokenRefreshCoordinator {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
