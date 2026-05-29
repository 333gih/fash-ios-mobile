import SwiftUI

struct HomeFeedContent: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: HomeViewModel
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var onOpenExplore: () -> Void = {}
    var onOpenFeaturedSellersAll: () -> Void = {}
    var onFeaturedSellerClick: (FeaturedSellerItem) -> Void = { _ in }
    var onRequestSignIn: (String) -> Void = { _ in }
    var onOpenSizingSetup: (() -> Void)? = nil
    var onDeliveringJourneyClick: () -> Void = {}
    var onSavedJourneyClick: () -> Void = {}
    var onInReviewJourneyClick: () -> Void = {}
    var onExploreShortcutClick: (HomeExploreShortcut) -> Void = { _ in }

    @State private var showStickyHomeTabs = false

    private var tabs: [HomeFeedTab] {
        viewModel.orderedTabs(isGuestMode: isGuestMode)
    }

    private var showGuestGate: Bool {
        isGuestMode && viewModel.selectedFeedTab.requiresAuth
    }

    private var promoSlides: [FashPromoSlideDef] {
        viewModel.promoSlides.map(FashPromoSlideDef.fromAdvertising)
    }

    private var promoDockInset: CGFloat {
        promoSlides.isEmpty ? 0 : FashStickyPromoDockHeight
    }

    private var selectedTabIndex: Int {
        tabs.firstIndex(of: viewModel.selectedFeedTab) ?? 0
    }

    private var analyticsSurface: String {
        viewModel.selectedFeedTab.analyticsSurface
    }

    private var showJourneyRow: Bool {
        !isGuestMode
    }

    private var exploreShortcut: HomeExploreShortcut? {
        isGuestMode ? nil : viewModel.homeUxPersonalization.exploreShortcut
    }

    private var followingPaginationEnabled: Bool {
        viewModel.selectedFeedTab == .following && viewModel.followingHasMore
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    homeScrollAwayHeader
                    homeFeedTabsInScroll
                    feedBody
                    HomeBrandFooterStrip()
                }
                .padding(.bottom, promoDockInset + spacing.spacing2)
                .fashScrollViewTabSwipe(
                    currentIndex: selectedTabIndex,
                    tabCount: tabs.count
                ) { index in
                    viewModel.selectFeedTab(tabs[index], deps: deps, isGuestMode: isGuestMode)
                }
            }
            .coordinateSpace(name: "homeFeedScroll")
            .background { HomeFeedTabsScrollObserver(showStickyTabs: $showStickyHomeTabs) }
            .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }

            if showStickyHomeTabs {
                homeFeedTabsStickyOverlay
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .zIndex(2)
            }

            if !promoSlides.isEmpty {
                FashPromoSliderAdFooterView(slides: promoSlides) { slide, _ in
                    router.handlePromoSlideClick(slide)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showStickyHomeTabs)
        .task {
            viewModel.normalizeSelectedFeedTab(isGuestMode: isGuestMode, deps: deps)
            await viewModel.loadShell(deps: deps, isGuestMode: isGuestMode, skipIfFresh: true)
        }
        .onChange(of: isGuestMode) { _, guest in
            viewModel.normalizeSelectedFeedTab(isGuestMode: guest, deps: deps)
        }
    }

    @ViewBuilder
    private var homeScrollAwayHeader: some View {
        VStack(spacing: 0) {
            if showJourneyRow {
                BuyerHomeJourneyCompactBar(
                    stats: viewModel.buyerStats,
                    onDeliveringClick: onDeliveringJourneyClick,
                    onSavedClick: onSavedJourneyClick,
                    onInReviewClick: onInReviewJourneyClick
                )
            }

            if viewModel.showSizingBanner, let onOpenSizingSetup {
                HomeSizingBanner(
                    onAddSizeClick: onOpenSizingSetup,
                    onDismiss: { viewModel.dismissSizingBanner() }
                )
            }

            if !viewModel.featuredSellers.isEmpty {
                HomeRecommendedSellersSection(
                    sellers: viewModel.featuredSellers,
                    onSellerClick: onFeaturedSellerClick,
                    onSeeAllClick: onOpenFeaturedSellersAll
                )
            }

            if let exploreShortcut {
                HomeExploreShortcutBanner(
                    shortcut: exploreShortcut,
                    onClick: { onExploreShortcutClick(exploreShortcut) }
                )
            }
        }
    }

    /// Tab row inside scroll — Android `home_feed_tabs` full-span item (not pinned).
    private var homeFeedTabsInScroll: some View {
        homeFeedTabsBar
            .homeFeedTabsScrollReporting()
    }

    private var homeFeedTabsStickyOverlay: some View {
        homeFeedTabsBar
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }

    private var homeFeedTabsBar: some View {
        VStack(spacing: 0) {
            HomeFeedTabSwitcher(
                tabs: tabs,
                selectedTab: viewModel.selectedFeedTab,
                isGuestBrowse: isGuestMode,
                onSelect: { tab in
                    viewModel.selectFeedTab(tab, deps: deps, isGuestMode: isGuestMode)
                }
            )
            Divider()
                .overlay(FashColors.outlineMuted.opacity(0.35))
        }
        .background(FashColors.screen)
    }

    @ViewBuilder
    private var feedBody: some View {
        if showGuestGate {
            HomeFeedTabGuestGate(tab: viewModel.selectedFeedTab) {
                onRequestSignIn(guestLoginReason(for: viewModel.selectedFeedTab))
            }
            .padding(.vertical, spacing.spacing4)
        } else if viewModel.isTabLoadError(viewModel.selectedFeedTab), viewModel.items.isEmpty {
            FashEmptyStateView(
                title: L10n.feedLoadError,
                subtitle: L10n.feedRetry,
                actionTitle: L10n.feedRetry
            ) {
                viewModel.retryTab(viewModel.selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
            }
            .padding(.vertical, spacing.spacing4)
        } else if (viewModel.isShellLoading || viewModel.isTabLoading(viewModel.selectedFeedTab)) && viewModel.items.isEmpty {
            FashSkeleton.listingGrid()
                .padding(.top, spacing.spacing2)
        } else if viewModel.items.isEmpty {
            if viewModel.selectedFeedTab == .following {
                HomePersonalizedFeedEmptyCard(
                    onExploreClick: onOpenExplore,
                    onFeaturedSellersClick: onOpenFeaturedSellersAll
                )
            } else {
                HomeFeedTabGenericEmpty(tab: viewModel.selectedFeedTab)
            }
        } else {
            VStack(spacing: 0) {
                ListingStaggeredMasonryView(items: viewModel.items) { item, index in
                    HomeFeedListingCell(
                        item: item,
                        index: index,
                        surface: analyticsSurface,
                        imageAspectRatio: ListingMasonryGrid.staggerAspectRatio(for: item.id),
                        onTap: {
                            viewModel.reportListingClick(
                                item: item,
                                surface: analyticsSurface,
                                position: index,
                                deps: deps
                            )
                            deps.presentListingPreview(
                                item: item,
                                router: router,
                                publicBrowse: isGuestMode,
                                surface: analyticsSurface,
                                position: index
                            )
                        },
                        onLike: {
                            viewModel.toggleLike(item, surface: analyticsSurface, position: index, deps: deps)
                        },
                        onSave: {
                            viewModel.toggleSave(
                                item,
                                surface: analyticsSurface,
                                position: index,
                                deps: deps,
                                isGuestMode: isGuestMode
                            )
                        },
                        onRecordView: {
                            viewModel.recordView(
                                item: item,
                                position: index,
                                surface: analyticsSurface,
                                deps: deps
                            )
                        },
                        onDwell: { dwellMs in
                            viewModel.recordDwell(
                                item: item,
                                surface: analyticsSurface,
                                position: index,
                                dwellMs: dwellMs,
                                deps: deps
                            )
                        }
                    )
                }

                FeedPaginationSentinel(
                    enabled: followingPaginationEnabled,
                    isLoadingMore: viewModel.isLoadingMoreFollowing
                ) {
                    viewModel.loadMoreFollowing(deps: deps, isGuestMode: isGuestMode)
                }

                if viewModel.selectedFeedTab == .following, viewModel.isLoadingMoreFollowing {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .padding(.vertical, 8)
                }
            }
            .padding(.top, spacing.spacing2)
            .padding(.bottom, spacing.spacing4)
        }
    }

    private func guestLoginReason(for tab: HomeFeedTab) -> String {
        switch tab {
        case .forYou: return L10n.guestLoginReasonHomeForYou
        case .following: return L10n.guestLoginReasonHomeFollowing
        case .stylePicks: return L10n.guestLoginReasonHomeStyle
        case .similarSaved: return L10n.guestLoginReasonHomeSimilar
        default: return L10n.guestLoginSheetTitle
        }
    }
}

private struct HomeFeedListingCell: View {
    let item: ListingFeedItem
    let index: Int
    let surface: String
    let imageAspectRatio: CGFloat
    let onTap: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void
    let onRecordView: () -> Void
    let onDwell: (Int) -> Void

    @State private var appearedAt: Date?

    var body: some View {
        ListingGridCard(
            item: item,
            onTap: onTap,
            imageAspectRatio: imageAspectRatio,
            showQuickActions: true,
            onLike: onLike,
            onSave: onSave
        )
        .onAppear {
            appearedAt = Date()
            onRecordView()
        }
        .onDisappear {
            if let appearedAt {
                let dwellMs = Int(Date().timeIntervalSince(appearedAt) * 1_000)
                onDwell(dwellMs)
            }
            self.appearedAt = nil
        }
    }
}
