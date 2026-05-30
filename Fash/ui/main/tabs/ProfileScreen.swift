import SwiftUI

struct ProfileScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ProfileViewModel
    var onEditProfile: () -> Void
    var onOpenFollowConnections: (Int) -> Void = { _ in }
    var onShippingAddressesClick: () -> Void = {}
    var onInviteFriendsClick: () -> Void = {}
    /// Wishlist and other buyer-facing taps — product detail / preview.
    var onListingClick: (String, String?) -> Void = { _, _ in }
    /// Own listings (selling, in review, rejected, sold) — Android `editListingId` from Profile.
    var onEditListingClick: (String) -> Void = { _ in }
    var onNavigateToExploreFromProfile: (
        _ categoryId: String?,
        _ brandId: String?,
        _ aestheticTagId: String?,
        _ searchQuery: String,
        _ countryId: String?,
        _ countryIso2: String?
    ) -> Void = { _, _, _, _, _, _ in }

    @State private var selectedTab = 0
    @State private var scrollToGridToken = 0
    /// Home journey → wishlist / in-review: pin grid after refresh settles (Android `pendingExternalGridScroll`).
    @State private var pendingExternalGridScroll = false

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
                    orderedTabIndices: viewModel.orderedProfileTabIndices,
                    items: currentItems,
                    showQuickActions: true,
                    scrollToGridToken: scrollToGridToken,
                    onListingClick: { item in handleListingTap(item) },
                    onLike: { item in Task { await viewModel.toggleLike(item, deps: deps) } },
                    onSave: { item in Task { await viewModel.toggleSave(item, deps: deps) } },
                    expandedHeader: { expandedHeader },
                    compactHeader: { compactHeader }
                )
                .refreshable { await viewModel.refresh(deps: deps) }
            }
        }
        .background(FashColors.screen)
        .task { await viewModel.refreshIfStale(deps: deps) }
        .onAppear {
            _ = applyProfileTabOpenRequestIfNeeded()
            applyPendingExternalGridScrollIfNeeded()
        }
        .onChange(of: viewModel.profileTabOpenGeneration) { _, _ in
            _ = applyProfileTabOpenRequestIfNeeded()
        }
        .onChange(of: viewModel.profile?.userId) { _, _ in
            guard viewModel.profile != nil else { return }
            if applyProfileTabOpenRequestIfNeeded() { return }
            if let tab = viewModel.consumePendingDefaultProfileTab() {
                selectedTab = tab
                viewModel.onProfileTabSelected(tab, deps: deps)
            }
        }
        .onChange(of: viewModel.isRefreshing) { _, _ in
            applyPendingExternalGridScrollIfNeeded()
        }
        .onChange(of: currentItems.count) { _, _ in
            applyPendingExternalGridScrollIfNeeded()
        }
        .onChange(of: selectedTab) { _, tab in
            viewModel.onProfileTabSelected(tab, deps: deps)
            applyPendingExternalGridScrollIfNeeded()
        }
    }

    private var currentItems: [ListingFeedItem] {
        viewModel.listings(for: ProfileListingTab(rawValue: selectedTab) ?? .active)
    }

    /// Selling / in-review / rejected / sold → edit listing; wishlist → PDP (Android Profile `onListingClick`).
    private func handleListingTap(_ item: ListingFeedItem) {
        switch ProfileListingTab(rawValue: selectedTab) ?? .active {
        case .wishlist:
            onListingClick(item.id, item.sellerId)
        case .active, .inReview, .rejected, .sold:
            onEditListingClick(item.id)
        }
    }

    /// Applies Home journey → Profile tab navigation. Returns true when consumed (Android `LaunchedEffect(profileTabOpenGen)`).
    @discardableResult
    private func applyProfileTabOpenRequestIfNeeded() -> Bool {
        guard viewModel.profileTabOpenGeneration != 0, viewModel.profile != nil else { return false }
        guard let req = viewModel.consumeProfileTabOpenRequest() else { return false }
        selectedTab = req.tab.rawValue
        viewModel.onProfileTabSelected(req.tab.rawValue, deps: deps)
        pendingExternalGridScroll = req.scrollToGrid
        applyPendingExternalGridScrollIfNeeded()
        return true
    }

    /// Scroll listing grid to pinned position once profile refresh finishes (parity with Android ProfileScreen).
    private func applyPendingExternalGridScrollIfNeeded() {
        guard pendingExternalGridScroll, !viewModel.isRefreshing else { return }
        pendingExternalGridScroll = false
        scrollToGridToken += 1
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
