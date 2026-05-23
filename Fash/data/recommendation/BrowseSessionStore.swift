import Foundation

/// Port of Android `BrowseSessionStore` (data.recommendation).
final class BrowseSessionStore {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
