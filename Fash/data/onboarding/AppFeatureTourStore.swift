import Foundation

/// Port of Android `AppFeatureTourStore` (data.onboarding).
final class AppFeatureTourStore {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
