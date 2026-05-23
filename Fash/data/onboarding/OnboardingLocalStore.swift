import Foundation

/// Port of Android `OnboardingLocalStore` (data.onboarding).
final class OnboardingLocalStore {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
