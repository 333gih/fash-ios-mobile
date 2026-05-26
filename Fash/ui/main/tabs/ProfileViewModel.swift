import Foundation
import Observation

private let profileStaleThresholdSeconds: TimeInterval = 60

@Observable
@MainActor
final class ProfileViewModel {
    var displayName = ""
    private var lastSuccessfulRefreshAt: Date?

    func refreshIfStale() async {
        if let last = lastSuccessfulRefreshAt,
           Date().timeIntervalSince(last) < profileStaleThresholdSeconds {
            return
        }
        await refresh(force: false)
    }

    func refresh(force: Bool = true) async {
        if !force,
           let last = lastSuccessfulRefreshAt,
           Date().timeIntervalSince(last) < profileStaleThresholdSeconds {
            return
        }
        lastSuccessfulRefreshAt = Date()
    }

    func requestInReviewTabFromHome() async {
        await refresh(force: true)
    }
}
