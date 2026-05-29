import SwiftUI

struct FollowConnectionsScreen: View {
    @Environment(AppDependencies.self) private var deps
    let initialTab: Int
    var onDismiss: () -> Void = {}
    var onUserClick: (UserSearchResult) -> Void = { _ in }

    @State private var viewModel = FollowConnectionsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                FashBackButton(action: onDismiss)
                Text(L10n.followConnectionsTitle)
                    .font(FashTypography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(FashColors.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.leading, FashBackButton.leadingScreenInset)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .background(FashColors.surface)

            Picker("", selection: Binding(
                get: { viewModel.selectedTab },
                set: { tab in Task { await viewModel.selectTab(tab, deps: deps) } }
            )) {
                Text(L10n.profileFollowing).tag(0)
                Text(L10n.profileFollowers).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            tabContent
        }
        .background(FashColors.screen)
        .task {
            await viewModel.show(initialTabIndex: initialTab, deps: deps)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        if viewModel.selectedTab == 0 {
            userList(
                users: viewModel.following,
                total: viewModel.followingTotal,
                loading: viewModel.followingLoading,
                loadingMore: viewModel.followingLoadingMore,
                failed: viewModel.followingFailed,
                emptyTitle: L10n.followListEmptyFollowingTitle,
                emptySubtitle: L10n.followListEmptyFollowingSubtitle,
                loadMore: { Task { await viewModel.loadMoreFollowing(deps: deps) } }
            )
        } else {
            userList(
                users: viewModel.followers,
                total: viewModel.followersTotal,
                loading: viewModel.followersLoading,
                loadingMore: viewModel.followersLoadingMore,
                failed: viewModel.followersFailed,
                emptyTitle: L10n.followListEmptyFollowersTitle,
                emptySubtitle: L10n.followListEmptyFollowersSubtitle,
                loadMore: { Task { await viewModel.loadMoreFollowers(deps: deps) } }
            )
        }
    }

    private func userList(
        users: [UserSearchResult],
        total: Int,
        loading: Bool,
        loadingMore: Bool,
        failed: Bool,
        emptyTitle: String,
        emptySubtitle: String,
        loadMore: @escaping () -> Void
    ) -> some View {
        Group {
            if failed && users.isEmpty {
                FashEmptyStateView(title: L10n.feedLoadError, actionTitle: L10n.feedRetry) {
                    Task { await viewModel.retryActiveTab(deps: deps) }
                }
            } else if loading && users.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if users.isEmpty {
                FashEmptyStateView(title: emptyTitle, subtitle: emptySubtitle)
            } else {
                List {
                    ForEach(users) { user in
                        Button {
                            onUserClick(user)
                        } label: {
                            followUserRow(user)
                        }
                        .buttonStyle(.plain)
                    }
                    if users.count < total {
                        HStack {
                            Spacer()
                            if loadingMore {
                                ProgressView()
                            } else {
                                Color.clear.frame(height: 1).onAppear(perform: loadMore)
                            }
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func followUserRow(_ user: UserSearchResult) -> some View {
        HStack(spacing: 14) {
            FashAvatarCircle(url: user.avatarUrl, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName.isEmpty ? user.username : user.displayName)
                    .font(FashTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(FashColors.textPrimary)
                    .lineLimit(1)
                if !user.username.isEmpty {
                    Text("@\(user.username)")
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(1)
                }
                if user.listingCount > 0 {
                    Text(L10n.productSellerListings(user.listingCount))
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
