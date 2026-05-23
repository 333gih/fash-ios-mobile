import Foundation

/// Port of Android `DealRepository` (data.deal).
final class DealRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
