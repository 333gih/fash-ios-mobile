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
        viewModel.isFirstPageLoading(for: selectedProfileTab)
    }

    private var showProfileBlockingLoader: Bool {
        viewModel.profile == nil && viewModel.isLoading && !showBlockingLoadError
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
                    ProfileCollapsingScrollLayout(
                        selectedTab: $selectedTab,
                        tabSet: .ownProfile,
                        orderedTabIndices: viewModel.orderedProfileTabIndices,
                        tabBadgeCounts: tabBadgeCount,
                        items: currentItems,
                        showQuickActions: selectedProfileTab == .wishlist,
                        showStatusOverlay: true,
                        suppressActiveStatusOnGrid: false,
                        showGridLoading: showListingGridLoading,
                        hasMoreListings: viewModel.hasMoreListings(for: selectedProfileTab),
                        isLoadingMoreListings: viewModel.isLoadingMoreListings(for: selectedProfileTab),
                        isReloadingListings: viewModel.isReloadingListings(for: selectedProfileTab),
                        onLoadMore: {
                            viewModel.requestLoadMore(for: selectedProfileTab, deps: deps)
                        },
                        showEmptyState: viewModel.hasCompletedInitialLoad,
                        isRefreshing: viewModel.isRefreshing,
                        lockScroll: showProfileBlockingLoader,
                        scrollToGridToken: scrollToGridToken,
                        scrollToListingId: viewModel.focusListingId,
                        scrollToListingToken: viewModel.focusListingScrollToken,
                        onListingClick: { item in handleListingTap(item) },
                        onLike: selectedProfileTab == .wishlist
                            ? { item in Task { await viewModel.toggleLike(item, deps: deps) } }
                            : nil,
                        onSave: selectedProfileTab == .wishlist
                            ? { item in Task { await viewModel.toggleSave(item, deps: deps) } }
                            : nil,
                        expandedHeader: { expandedHeader },
                        compactHeader: { compactHeader }
                    )
                    .refreshable {
                        await viewModel.refresh(deps: deps, activeTab: selectedProfileTab)
                    }
                    .allowsHitTesting(!showProfileBlockingLoader)

                    if showProfileBlockingLoader {
                        ZStack {
                            FashColors.screen.opacity(0.72)
                            ProgressView()
                                .tint(FashColors.brandPrimary)
                                .scaleEffect(1.1)
                        }
                        .ignoresSafeArea()
                        .allowsHitTesting(true)
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
            _ = applyProfileTabOpenRequestIfNeeded()
            applyPendingExternalGridScrollIfNeeded()
            Task { await viewModel.ensureListingsLoaded(for: selectedProfileTab, deps: deps) }
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
        viewModel.listings(for: selectedProfileTab)
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
        guard pendingExternalGridScroll,
              viewModel.hasCompletedInitialLoad,
              !viewModel.isRefreshing else { return }
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

    private var compactHeader: some View {
        ProfileCompactHeaderBar(profile: viewModel.profile)
    }
}
