import Foundation

/// Port of Android `WelcomeDialogStore` (data.welcome).
final class WelcomeDialogStore {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
