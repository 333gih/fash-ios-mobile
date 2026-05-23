import Foundation

/// Port of Android `AppPromoInterstitialRepository` (data.promo).
final class AppPromoInterstitialRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
