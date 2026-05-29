import SwiftUI

struct ProfileScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ProfileViewModel
    var onEditProfile: () -> Void
    var onOpenFollowConnections: (Int) -> Void = { _ in }
    var onShippingAddressesClick: () -> Void = {}
    var onInviteFriendsClick: () -> Void = {}
    var onListingClick: (String, String?) -> Void = { _, _ in }
    var onNavigateToExploreFromProfile: (
        _ categoryId: String?,
        _ brandId: String?,
        _ aestheticTagId: String?,
        _ searchQuery: String,
        _ countryId: String?,
        _ countryIso2: String?
    ) -> Void = { _, _, _, _, _, _ in }

    @State private var selectedTab = 0

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.profile == nil {
                ProgressView()
                    .tint(FashColors.brandPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.loadError && viewModel.profile == nil {
                FashEmptyStateView(
                    title: L10n.profileLoadError,
                    actionTitle: L10n.feedRetry
                ) {
                    Task { await viewModel.refresh(deps: deps) }
                }
            } else {
                ProfileCollapsingScrollLayout(
                    selectedTab: $selectedTab,
                    tabSet: .ownProfile,
                    items: currentItems,
                    showQuickActions: true,
                    onListingClick: { item in onListingClick(item.id, item.sellerId) },
                    onLike: { item in Task { await viewModel.toggleLike(item, deps: deps) } },
                    onSave: { item in Task { await viewModel.toggleSave(item, deps: deps) } },
                    expandedHeader: { expandedHeader },
                    compactHeader: { compactHeader }
                )
                .refreshable { await viewModel.refresh(deps: deps) }
            }
        }
        .background(FashColors.screen)
        .task { await viewModel.refresh(deps: deps) }
        .onChange(of: viewModel.profileTabOpenGeneration) { _, _ in
            applyProfileTabOpenRequestIfNeeded()
        }
        .onChange(of: viewModel.profile?.userId) { _, _ in
            applyProfileTabOpenRequestIfNeeded()
            if viewModel.profileTabOpenGeneration == 0,
               let tab = viewModel.consumePendingDefaultProfileTab() {
                selectedTab = tab
                viewModel.onProfileTabSelected(tab, deps: deps)
            }
        }
        .onChange(of: selectedTab) { _, tab in
            viewModel.onProfileTabSelected(tab, deps: deps)
        }
    }

    private var currentItems: [ListingFeedItem] {
        viewModel.listings(for: ProfileListingTab(rawValue: selectedTab) ?? .active)
    }

    private func applyProfileTabOpenRequestIfNeeded() {
        guard viewModel.profileTabOpenGeneration != 0, viewModel.profile != nil else { return }
        guard let req = viewModel.consumeProfileTabOpenRequest() else { return }
        selectedTab = req.tab.rawValue
        viewModel.onProfileTabSelected(req.tab.rawValue, deps: deps)
    }

    @ViewBuilder
    private var expandedHeader: some View {
        ProfileHeroSection(
            coverImageUrl: viewModel.profile?.coverImageUrl ?? viewModel.coverImageUrl,
            avatarUrl: viewModel.profile?.avatarUrl ?? viewModel.avatarUrl
        )
        ProfileIdentityBlock(
            profile: viewModel.profile,
            showEditButton: true,
            aestheticCatalog: viewModel.aestheticCatalog,
            onEdit: onEditProfile,
            onAestheticTagClick: { _, tagId in
                onNavigateToExploreFromProfile(nil, nil, tagId, "", nil, nil)
            }
        )
        ProfileOwnMetricsCard(
            profile: viewModel.profile,
            onFollowersTap: { onOpenFollowConnections(1) },
            onFollowingTap: { onOpenFollowConnections(0) }
        )
        ProfileSizingReferenceCard(profile: viewModel.profile, onEdit: onEditProfile)
        ProfileQuickActionsCard(
            username: viewModel.profile?.username ?? viewModel.username,
            displayName: viewModel.profile?.displayName ?? viewModel.displayName,
            onShipping: onShippingAddressesClick,
            onInvite: onInviteFriendsClick
        )
    }

    private var compactHeader: some View {
        ProfileCompactHeaderBar(profile: viewModel.profile)
    }
}
