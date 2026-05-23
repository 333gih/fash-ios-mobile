import Foundation

/// Port of Android `AppAuthManager` (data.auth).
final class AppAuthManager {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
