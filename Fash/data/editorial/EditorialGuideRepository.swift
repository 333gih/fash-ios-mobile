import Foundation

/// Port of Android `EditorialGuideRepository` (data.editorial).
final class EditorialGuideRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
