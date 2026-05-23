import Foundation

/// Port of Android `OrderCancelCoordinator` (data.order).
final class OrderCancelCoordinator {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
