import SwiftUI

struct SellerProfileScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    let username: String
    var isGuestMode: Bool = false
    var onDismiss: () -> Void
    var onListingClick: (ListingFeedItem) -> Void = { _ in }
    var onNavigateToExploreFromProfile: (
        _ categoryId: String?,
        _ brandId: String?,
        _ aestheticTagId: String?,
        _ searchQuery: String,
        _ countryId: String?,
        _ countryIso2: String?
    ) -> Void = { _, _, _, _, _, _ in }

    @State private var viewModel = SellerProfileViewModel()
    @State private var promoSlides: [FashPromoSlideDef] = []
    @State private var showPromoFooter = false
    @State private var showGuestLoginSheet = false
    @State private var guestLoginReason: String?
    @State private var sharePayload: FashSharePayload?
    @State private var sellerScrollBoundary = HomeFeedScrollBoundary()

    private var sellerRefreshBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isRefreshing },
            set: { viewModel.isRefreshing = $0 }
        )
    }

    private var promoBottomInset: CGFloat {
        showPromoFooter && !promoSlides.isEmpty ? FashStickyPromoDockHeight : 0
    }

    private var showBlockingLoadError: Bool {
        viewModel.loadError && viewModel.profile == nil && !viewModel.isLoading && !viewModel.isRefreshing
    }

    private var selectedSellerTab: SellerProfileTab {
        SellerProfileTab(rawValue: viewModel.selectedTab) ?? .selling
    }

    private var showListingGridLoading: Bool {
        viewModel.shouldShowListingGridSkeleton(for: selectedSellerTab)
    }

    private var showListingGridLoadRetry: Bool {
        viewModel.isListingTabStalled(selectedSellerTab) && viewModel.listingsForSelectedTab.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                sellerTopBar
                ZStack(alignment: .bottom) {
                    Group {
                        if showBlockingLoadError {
                            FashEmptyStateView(title: L10n.profileLoadError, actionTitle: L10n.feedRetry) {
                                Task { await viewModel.loadForSeller(username, deps: deps, isGuestMode: isGuestMode) }
                            }
                        } else {
                            ProfileCollapsingScrollLayout(
                            selectedTab: $viewModel.selectedTab,
                            tabSet: .sellerStorefront,
                            items: viewModel.listingsForSelectedTab,
                            showQuickActions: true,
                            showStatusOverlay: true,
                            additionalBottomInset: promoBottomInset,
                            useStaggeredMasonryGrid: true,
                            masonryEagerLayout: false,
                            showGridLoading: showListingGridLoading,
                            showGridLoadRetry: showListingGridLoadRetry,
                            onRetryGridLoad: {
                                Task {
                                    await viewModel.retryListings(
                                        for: selectedSellerTab,
                                        deps: deps,
                                        isGuestMode: isGuestMode
                                    )
                                }
                            },
                            hasMoreListings: viewModel.hasMoreListings(for: selectedSellerTab),
                            isLoadingMoreListings: viewModel.isLoadingMoreListings(for: selectedSellerTab),
                            isReloadingListings: viewModel.isReloadingListings(for: selectedSellerTab),
                            onLoadMore: {
                                viewModel.requestLoadMore(
                                    for: selectedSellerTab,
                                    deps: deps,
                                    isGuestMode: isGuestMode
                                )
                            },
                            showEmptyState: viewModel.hasCompletedInitialLoad,
                            isRefreshing: viewModel.isRefreshing,
                            lockScroll: false,
                            onTabsPinnedAtTopChange: { pinned in
                                showPromoFooter = pinned
                            },
                            onTabHorizontalSwipeActive: { active in
                                if active {
                                    deps.listingPreview.close(deps: deps, animated: false)
                                }
                            },
                            enableScrollProximityLoadMore: false,
                            enableTilePrefetchLoadMore: false,
                            loadMoreSkeletonRows: 0,
                            suppressScrollClamp: true,
                            loadMoreAtScrollBottom: true,
                            bottomLoadMoreTolerance: 36,
                            feedScrollBoundary: sellerScrollBoundary,
                            feedTrimCompensationToken: viewModel.listingScrollTrimToken,
                            feedTrimCompensationSignedDeltaY: viewModel.listingScrollTrimSignedDeltaY,
                            onListingCellVisible: { index, columnWidth in
                                viewModel.notifyListingCellVisible(
                                    tab: selectedSellerTab,
                                    visibleIndex: index,
                                    columnWidth: columnWidth,
                                    deps: deps,
                                    isGuestMode: isGuestMode
                                )
                            },
                            onListingClick: { item in onListingClick(item) },
                            onLike: { item in
                                if isGuestMode { presentGuestSignIn(reason: L10n.guestLoginReasonLike) }
                                else { Task { await viewModel.toggleLike(item, deps: deps) } }
                            },
                            onSave: { item in
                                if isGuestMode { presentGuestSignIn(reason: L10n.guestLoginReasonSaved) }
                                else { Task { await viewModel.toggleSave(item, deps: deps) } }
                            },
                            expandedHeader: { expandedHeader },
                            compactHeader: { ProfileCompactHeaderBar(profile: viewModel.profile) }
                        )
                        .fashFeedPullRefresh(isRefreshing: sellerRefreshBinding) {
                            await viewModel.loadForSeller(username, deps: deps, isGuestMode: isGuestMode, force: true)
                        }
                        }
                    }

                    if !promoSlides.isEmpty {
                        StickyBottomPromoBar {
                            FashPromoSliderView(slides: promoSlides) { slide, _ in
                                onDismiss()
                                deps.navigationRouter?.handlePromoSlideClick(slide)
                            }
                        }
                        .opacity(showPromoFooter ? 1 : 0)
                        .allowsHitTesting(showPromoFooter)
                        .accessibilityHidden(!showPromoFooter)
                    }
                }
            }

            ListingPreviewOverlay(
                listingPreview: deps.listingPreview,
                router: router,
                isGuestMode: isGuestMode,
                onRequestLogin: isGuestMode ? { presentGuestSignIn(reason: L10n.guestLoginReasonBuy) } : nil,
                onFeedEngagementPatch: { id, transform in
                    viewModel.patchListingEngagement(id, transform: transform)
                }
            )
            .zIndex(30)
        }
        .background(FashColors.screen)
        .onChange(of: username) { _, _ in
            showPromoFooter = false
            viewModel.selectedTab = SellerProfileTab.selling.rawValue
        }
        .onChange(of: viewModel.selectedTab) { _, tab in
            deps.listingPreview.close(deps: deps, animated: false)
            viewModel.onTabSelected(tab, deps: deps, isGuestMode: isGuestMode)
        }
        .onChange(of: viewModel.profile?.userId) { _, _ in
            guard viewModel.profile != nil else { return }
            Task {
                await viewModel.ensureListingsLoaded(
                    for: selectedSellerTab,
                    deps: deps,
                    isGuestMode: isGuestMode
                )
            }
        }
        .task(id: username) {
            await viewModel.loadForSeller(username, deps: deps, isGuestMode: isGuestMode)
            if case .success(let response) = await deps.advertisingRepository.getSlides(publicBrowse: isGuestMode) {
                promoSlides = response.items.map(FashPromoSlideDef.fromAdvertising)
            }
        }
        .onAppear {
            viewModel.scrollBoundary = sellerScrollBoundary
        }
        .guestLoginSheet(
            isPresented: $showGuestLoginSheet,
            reason: guestLoginReason,
            router: router
        )
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: payload.items) { completed in
                FashActivityShare.showSuccessIfNeeded(
                    completed,
                    message: L10n.shareProfileSuccess,
                    deps: deps
                )
            }
        }
    }

    private func presentGuestSignIn(reason: String) {
        guestLoginReason = reason
        showGuestLoginSheet = true
    }

    private var sellerTopBar: some View {
        HStack(spacing: 8) {
            FashBackButton(action: onDismiss)
            Text(titleHandle)
                .font(FashTypography.titleMedium.weight(.semibold))
                .lineLimit(1)
            Spacer()
            if !titleHandle.isEmpty, titleHandle != "—" {
                Button {
                    let handle = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
                    sharePayload = ProfileShare.sharePayload(
                        username: handle,
                        displayName: viewModel.profile?.displayName
                    )
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }
            }
        }
        .padding(.leading, FashBackButton.leadingScreenInset)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(FashColors.screen)
    }

    @ViewBuilder
    private var expandedHeader: some View {
        if viewModel.isShellLoading {
            SellerProfileShellSkeleton()
        } else {
            sellerProfileLoadedHeader
        }
    }

    @ViewBuilder
    private var sellerProfileLoadedHeader: some View {
        VStack(spacing: 0) {
            ProfileHeroSection(
                coverImageUrl: viewModel.profile?.coverImageUrl,
                avatarUrl: viewModel.profile?.avatarUrl
            )
            ProfileIdentityBlock(
                profile: viewModel.profile,
                showEditButton: false,
                aestheticCatalog: viewModel.aestheticCatalog,
                onAestheticTagClick: { label, tagId in
                    let p = ExploreProfileFilterRequest.forAestheticChip(label: label, tagId: tagId)
                    onNavigateToExploreFromProfile(nil, nil, p.aestheticTagId, p.searchQuery, nil, nil)
                }
            )
            if viewModel.canShowFollowUi(deps: deps, isGuestMode: isGuestMode) {
                SellerProfileFollowBlock(
                    isFollowing: viewModel.isFollowing && !isGuestMode,
                    inFlight: viewModel.followInFlight,
                    onToggle: {
                        if isGuestMode { presentGuestSignIn(reason: L10n.guestLoginReasonFollow) }
                        else { Task { await viewModel.toggleFollow(deps: deps, isGuestMode: isGuestMode) } }
                    }
                )
            }
            SellerProfileMetricsCard(profile: viewModel.profile)
            SellerProfileBodyMeasurements(profile: viewModel.profile)
            SellerProfileTopBadges(profile: viewModel.profile)
            SellerListingFocusSection(
                focus: viewModel.sellerFocus,
                forbidden: viewModel.sellerFocusForbidden,
                loading: viewModel.sellerFocusLoading,
                aestheticCatalog: viewModel.aestheticCatalog,
                onCategory: { id, _ in onNavigateToExploreFromProfile(id, nil, nil, "", nil, nil) },
                onBrand: { id, _ in onNavigateToExploreFromProfile(nil, id, nil, "", nil, nil) },
                onAesthetic: { id, name in
                    let p = ExploreProfileFilterRequest.forAestheticChip(label: name, tagId: id)
                    onNavigateToExploreFromProfile(nil, nil, p.aestheticTagId, p.searchQuery, nil, nil)
                }
            )
        }
    }

    private var titleHandle: String {
        let h = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        return h.isEmpty ? "—" : "@\(h)"
    }
}
