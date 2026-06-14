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

    private var showBlockingLoadError: Bool {
        viewModel.loadError && viewModel.profile == nil && !viewModel.isLoading && !viewModel.isRefreshing
    }

    private var selectedProfileTab: ProfileListingTab {
        ProfileListingTab(rawValue: selectedTab) ?? .active
    }

    private var showListingGridLoading: Bool {
        viewModel.shouldShowListingGridSkeleton(for: selectedProfileTab)
    }

    private var showListingGridLoadRetry: Bool {
        viewModel.isListingTabStalled(selectedProfileTab) && currentItems.isEmpty
    }

    private func tabBadgeCount(for index: Int) -> Int? {
        guard let tab = ProfileListingTab(rawValue: index) else { return nil }
        let count = viewModel.displayCount(for: tab)
        return count > 0 ? count : nil
    }

    var body: some View {
        Group {
            if showBlockingLoadError {
                FashEmptyStateView(
                    title: L10n.profileLoadError,
                    actionTitle: L10n.feedRetry
                ) {
                    Task { await viewModel.refresh(deps: deps) }
                }
            } else {
                ZStack {
                    profileCollapsingScroll
                        .fashFeedPullRefresh(isRefreshing: $viewModel.isRefreshing) {
                            await viewModel.refresh(deps: deps, activeTab: selectedProfileTab)
                        }
                }
            }
        }
        .background(FashColors.screen)
        .task { await viewModel.refreshIfStale(deps: deps) }
        .task(id: selectedTab) {
            await viewModel.ensureListingsLoaded(for: selectedProfileTab, deps: deps)
        }
        .onAppear {
            syncSelectedTabFromViewModel()
            _ = applyProfileTabOpenRequestIfNeeded()
            tryApplyPendingExternalGridScroll()
            Task { await viewModel.ensureListingsLoaded(for: selectedProfileTab, deps: deps) }
        }
        .onChange(of: viewModel.profileTabOpenGeneration) { _, _ in
            _ = applyProfileTabOpenRequestIfNeeded()
            tryApplyPendingExternalGridScroll()
        }
        .onChange(of: viewModel.profile?.userId) { _, _ in
            guard viewModel.profile != nil else { return }
            if applyProfileTabOpenRequestIfNeeded() { return }
            if let tab = viewModel.consumePendingDefaultProfileTab() {
                selectedTab = tab
                viewModel.onProfileTabSelected(tab, deps: deps)
            } else {
                syncSelectedTabFromViewModel()
            }
            tryApplyPendingExternalGridScroll()
        }
        .onChange(of: viewModel.isRefreshing) { _, _ in
            tryApplyPendingExternalGridScroll()
        }
        .onChange(of: viewModel.hasCompletedInitialLoad) { _, _ in
            tryApplyPendingExternalGridScroll()
        }
        .onChange(of: showListingGridLoading) { _, _ in
            tryApplyPendingExternalGridScroll()
        }
        .onChange(of: currentItems.count) { _, _ in
            tryApplyPendingExternalGridScroll()
        }
        .onChange(of: selectedTab) { _, tab in
            viewModel.onProfileTabSelected(tab, deps: deps)
            tryApplyPendingExternalGridScroll()
        }
    }

    private var currentItems: [ListingFeedItem] {
        viewModel.listings(for: selectedProfileTab)
    }

    private var profileCollapsingScroll: some View {
        ProfileCollapsingScrollLayout(
            selectedTab: $selectedTab,
            tabSet: .ownProfile,
            orderedTabIndices: viewModel.orderedProfileTabIndices,
            tabBadgeCounts: tabBadgeCount,
            items: currentItems,
            showQuickActions: selectedProfileTab == .wishlist,
            showStatusOverlay: true,
            suppressActiveStatusOnGrid: false,
            useStaggeredMasonryGrid: true,
            masonryEagerLayout: true,
            showGridLoading: showListingGridLoading,
            showGridLoadRetry: showListingGridLoadRetry,
            onRetryGridLoad: profileRetryGridLoad,
            hasMoreListings: viewModel.hasMoreListings(for: selectedProfileTab),
            isLoadingMoreListings: viewModel.isLoadingMoreListings(for: selectedProfileTab),
            isReloadingListings: viewModel.isReloadingListings(for: selectedProfileTab),
            onLoadMore: profileLoadMore,
            showEmptyState: viewModel.hasCompletedInitialLoad,
            isRefreshing: viewModel.isRefreshing,
            lockScroll: false,
            scrollToGridToken: scrollToGridToken,
            scrollToTopToken: viewModel.profileScrollToTopToken,
            scrollToListingId: viewModel.focusListingId,
            scrollToListingToken: viewModel.focusListingScrollToken,
            enableScrollProximityLoadMore: true,
            onListingClick: handleListingTap,
            onLike: profileWishlistLikeHandler,
            onSave: profileWishlistSaveHandler,
            expandedHeader: { expandedHeader },
            compactHeader: { compactHeader }
        )
    }

    private func profileRetryGridLoad() {
        Task { await viewModel.retryListings(for: selectedProfileTab, deps: deps) }
    }

    private func profileLoadMore() {
        viewModel.requestLoadMore(for: selectedProfileTab, deps: deps)
    }

    private var profileWishlistLikeHandler: ((ListingFeedItem) -> Void)? {
        guard selectedProfileTab == .wishlist else { return nil }
        return { item in Task { await viewModel.toggleLike(item, deps: deps) } }
    }

    private var profileWishlistSaveHandler: ((ListingFeedItem) -> Void)? {
        guard selectedProfileTab == .wishlist else { return nil }
        return { item in Task { await viewModel.toggleSave(item, deps: deps) } }
    }

    /// Selling / in-review / rejected / sold → edit listing; wishlist → PDP (Android Profile `onListingClick`).
    private func handleListingTap(_ item: ListingFeedItem) {
        switch ProfileListingTab(rawValue: selectedTab) ?? .active {
        case .wishlist:
            onListingClick(item.id, item.sellerId)
        case .active, .inReview, .rejected, .sold:
            viewModel.prepareEditReturn(tab: selectedProfileTab, listingId: item.id)
            onEditListingClick(item.id)
        }
    }

    private func syncSelectedTabFromViewModel() {
        let vmTab = viewModel.lastSelectedProfileTab
        guard viewModel.profile != nil, selectedTab != vmTab else { return }
        selectedTab = vmTab
    }

    /// Applies Home journey → Profile tab navigation. Returns true when consumed (Android `LaunchedEffect(profileTabOpenGen)`).
    @discardableResult
    private func applyProfileTabOpenRequestIfNeeded() -> Bool {
        guard viewModel.profileTabOpenGeneration != 0, viewModel.profile != nil else { return false }
        guard let req = viewModel.consumeProfileTabOpenRequest() else { return false }
        selectedTab = req.tab.rawValue
        viewModel.onProfileTabSelected(req.tab.rawValue, deps: deps)
        pendingExternalGridScroll = req.scrollToGrid
        tryApplyPendingExternalGridScroll()
        return true
    }

    /// Scroll listing grid to pinned tabs once refresh + first-page load settle (Android `LaunchedEffect(pendingExternalGridScroll, …)`).
    private func tryApplyPendingExternalGridScroll() {
        guard pendingExternalGridScroll else { return }
        guard viewModel.hasCompletedInitialLoad else { return }
        guard !viewModel.isRefreshing else { return }
        guard !showListingGridLoading else { return }
        pendingExternalGridScroll = false
        scrollToGridToken += 1
    }

    @ViewBuilder
    private var expandedHeader: some View {
        VStack(spacing: 0) {
            ProfileHeroSection(
                coverImageUrl: viewModel.profile?.coverImageUrl ?? viewModel.coverImageUrl,
                avatarUrl: viewModel.profile?.avatarUrl ?? viewModel.avatarUrl
            )
            ProfileIdentityBlock(
                profile: viewModel.profile,
                showEditButton: true,
                aestheticCatalog: viewModel.aestheticCatalog,
                onEdit: onEditProfile,
                onAestheticTagClick: { label, tagId in
                    let p = ExploreProfileFilterRequest.forAestheticChip(label: label, tagId: tagId)
                    onNavigateToExploreFromProfile(nil, nil, p.aestheticTagId, p.searchQuery, nil, nil)
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
    }

    private var compactHeader: some View {
        ProfileCompactHeaderBar(profile: viewModel.profile)
    }
}
