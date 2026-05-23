import Foundation

/// Port of Android `AppPromoCampaignStore` (data.promo).
final class AppPromoCampaignStore {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
