import Foundation
import Observation

private let profileStaleThresholdSeconds: TimeInterval = 60

@Observable
@MainActor
final class ProfileViewModel {
    var displayName = ""
    var username = ""
    var avatarUrl = ""
    var coverImageUrl = ""
    var bio = ""
    var followerCount = 0
    var followingCount = 0
    var productCount = 0
    var isLoading = false
    var loadError = false
    private var lastSuccessfulRefreshAt: Date?

    func refreshIfStale(deps: AppDependencies) async {
        if let last = lastSuccessfulRefreshAt,
           Date().timeIntervalSince(last) < profileStaleThresholdSeconds {
            return
        }
        await refresh(deps: deps, force: false)
    }

    func refresh(deps: AppDependencies, force: Bool = true) async {
        if !force,
           let last = lastSuccessfulRefreshAt,
           Date().timeIntervalSince(last) < profileStaleThresholdSeconds {
            return
        }
        isLoading = true
        loadError = false
        defer { isLoading = false }
        let result = await deps.userRepository.getMeProfile()
        switch result {
        case .success(let profile):
            displayName = profile.displayName.isEmpty ? profile.username : profile.displayName
            username = profile.username
            avatarUrl = profile.avatarUrl
            coverImageUrl = profile.coverImageUrl
            bio = profile.bio
            followerCount = profile.followerCount
            followingCount = profile.followingCount
            productCount = profile.productCount
            lastSuccessfulRefreshAt = Date()
            loadError = false
        case .failure:
            loadError = true
        }
    }

    func requestInReviewTabFromHome(deps: AppDependencies) async {
        await refresh(deps: deps, force: true)
    }
}
