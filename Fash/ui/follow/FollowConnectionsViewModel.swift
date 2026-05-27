import Foundation
import Observation

@Observable
@MainActor
final class FollowConnectionsViewModel {
    var selectedTab = 0
    var following: [UserSearchResult] = []
    var followers: [UserSearchResult] = []
    var followingTotal = 0
    var followersTotal = 0
    var followingLoading = false
    var followersLoading = false
    var followingLoadingMore = false
    var followersLoadingMore = false
    var followingFailed = false
    var followersFailed = false

    func show(initialTabIndex: Int, deps: AppDependencies) async {
        selectedTab = min(max(initialTabIndex, 0), 1)
        await loadTab(selectedTab, refresh: true, deps: deps)
    }

    func selectTab(_ index: Int, deps: AppDependencies) async {
        let i = min(max(index, 0), 1)
        guard selectedTab != i else { return }
        selectedTab = i
        await loadTab(i, refresh: false, deps: deps)
    }

    func retryActiveTab(deps: AppDependencies) async {
        await loadTab(selectedTab, refresh: true, deps: deps)
    }

    func loadMoreFollowing(deps: AppDependencies) async {
        guard !followingLoading, !followingLoadingMore, following.count < followingTotal else { return }
        followingLoadingMore = true
        defer { followingLoadingMore = false }
        switch await deps.userRepository.getMyFollowing(limit: 20, offset: following.count) {
        case .success(let page):
            following.append(contentsOf: page.items)
            followingTotal = page.total
            followingFailed = false
        case .failure:
            followingFailed = true
        }
    }

    func loadMoreFollowers(deps: AppDependencies) async {
        guard !followersLoading, !followersLoadingMore, followers.count < followersTotal else { return }
        followersLoadingMore = true
        defer { followersLoadingMore = false }
        switch await deps.userRepository.getMyFollowers(limit: 20, offset: followers.count) {
        case .success(let page):
            followers.append(contentsOf: page.items)
            followersTotal = page.total
            followersFailed = false
        case .failure:
            followersFailed = true
        }
    }

    private func loadTab(_ tab: Int, refresh: Bool, deps: AppDependencies) async {
        if tab == 0 {
            await loadFollowing(refresh: refresh, deps: deps)
        } else {
            await loadFollowers(refresh: refresh, deps: deps)
        }
    }

    private func loadFollowing(refresh: Bool, deps: AppDependencies) async {
        if !refresh, !following.isEmpty { return }
        followingLoading = true
        followingFailed = false
        defer { followingLoading = false }
        switch await deps.userRepository.getMyFollowing(limit: 20, offset: 0) {
        case .success(let page):
            following = page.items
            followingTotal = page.total
        case .failure:
            following = []
            followingFailed = true
        }
    }

    private func loadFollowers(refresh: Bool, deps: AppDependencies) async {
        if !refresh, !followers.isEmpty { return }
        followersLoading = true
        followersFailed = false
        defer { followersLoading = false }
        switch await deps.userRepository.getMyFollowers(limit: 20, offset: 0) {
        case .success(let page):
            followers = page.items
            followersTotal = page.total
        case .failure:
            followers = []
            followersFailed = true
        }
    }
}
