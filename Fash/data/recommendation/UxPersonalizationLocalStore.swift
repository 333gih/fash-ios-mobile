import Foundation

/// Port of Android `UxPersonalizationLocalStore` (data.recommendation).
final class UxPersonalizationLocalStore {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
