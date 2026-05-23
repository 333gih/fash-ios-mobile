import Foundation

/// Port of Android `CorePaymentRepository` (data.payment).
final class CorePaymentRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
