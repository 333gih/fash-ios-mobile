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

    /// Avoid collapsed empty gap while tab content swaps during horizontal swipe.
    private var homeFeedMinHeight: CGFloat {
        if !viewModel.items.isEmpty { return 0 }
        if viewModel.isRefreshing { return 280 }
        if viewModel.isShellLoading || viewModel.isTabLoading(viewModel.selectedFeedTab) {
            return 520
        }
        return 300
    }

    @State private var homeScrollPosition: String?
    @State private var homeScrollResetToken = 0
    @State private var scrollClampRevision = 0
    @State private var homeHeaderHeight: CGFloat = 0
    @State private var pendingPinnedFeedScroll = false
    @State private var masonryColumnAssignmentsByTab: [String: [String: Bool]] = [:]
    @State private var listingInteractionEnabled = true
    @State private var tabSlideDirection: Int = 0

    private var masonryColumnAssignments: Binding<[String: Bool]> {
        Binding(
            get: { masonryColumnAssignmentsByTab[viewModel.selectedFeedTabKey] ?? [:] },
            set: { masonryColumnAssignmentsByTab[viewModel.selectedFeedTabKey] = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            homeScrollAwayHeader
                                .homeFeedHeaderHeightReporting()
                        }
                        Section {
                            feedBody
                                .id(HomeScrollIds.feedContent)
                                .frame(minHeight: homeFeedMinHeight, alignment: .top)
                            HomeBrandFooterStrip()
                        } header: {
                            homeFeedTabsBar
                                .id(HomeScrollIds.pinnedTabs)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.bottom, promoDockInset + spacing.spacing2)
                    .fashScrollViewTabSwipe(
                        currentIndex: selectedTabIndex,
                        tabCount: tabs.count,
                        listingInteractionEnabled: $listingInteractionEnabled
                    ) { index in
                        tabSlideDirection = index > selectedTabIndex ? 1 : -1
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            viewModel.selectFeedTab(tabs[index], deps: deps, isGuestMode: isGuestMode)
                        }
                    }
                }
                .coordinateSpace(name: "homeFeedScroll")
                .scrollPosition(id: $homeScrollPosition, anchor: .top)
                .background {
                    PinnedTabScrollOffsetFixer(
                        resetToken: homeScrollResetToken,
                        clampRevision: scrollClampRevision,
                        headerHeight: homeHeaderHeight
                    )
                }
                .onHomeHeaderHeightChange($homeHeaderHeight)
                .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }
                .onChange(of: viewModel.homeScrollToTopToken) { _, _ in
                    scrollHomeToTop(using: scrollProxy)
                }
                .onChange(of: viewModel.selectedFeedTabKey) { oldKey, newKey in
                    guard oldKey != newKey else { return }
                    applyPinnedFeedScroll(using: scrollProxy)
                    pendingPinnedFeedScroll = viewModel.isTabLoading(viewModel.selectedFeedTab)
                }
                .onChange(of: viewModel.items.count) { _, _ in
                    scrollClampRevision += 1
                }
                .onChange(of: viewModel.tabsLoading) { _, _ in
                    guard pendingPinnedFeedScroll else { return }
                    guard !viewModel.isTabLoading(viewModel.selectedFeedTab) else { return }
                    pendingPinnedFeedScroll = false
                    applyPinnedFeedScroll(using: scrollProxy)
                }
            }

            if !promoSlides.isEmpty {
                FashPromoSliderAdFooterView(slides: promoSlides) { slide, _ in
                    router.handlePromoSlideClick(slide)
                }
            }
        }
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

    /// Tab row — pinned at top once header scrolls away (Android `showStickyTabs` overlay).
    private var homeFeedTabsBar: some View {
        VStack(spacing: 0) {
            HomeFeedTabSwitcher(
                tabs: tabs,
                selectedTab: viewModel.selectedFeedTab,
                isGuestBrowse: isGuestMode,
                onSelect: { tab in
                    if let oldIdx = tabs.firstIndex(of: viewModel.selectedFeedTab),
                       let newIdx = tabs.firstIndex(of: tab), oldIdx != newIdx {
                        tabSlideDirection = newIdx > oldIdx ? 1 : -1
                    }
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                        viewModel.selectFeedTab(tab, deps: deps, isGuestMode: isGuestMode)
                    }
                }
            )
            Divider()
                .overlay(FashColors.outlineMuted.opacity(0.35))
        }
        .background(FashColors.screen)
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }

    @ViewBuilder
    private var feedBody: some View {
        Group {
            feedBodyContent
        }
        .id(viewModel.selectedFeedTabKey)
        .allowsHitTesting(listingInteractionEnabled)
        .transition(
            .asymmetric(
                insertion: .opacity.combined(with: .offset(x: CGFloat(tabSlideDirection) * 28)),
                removal: .opacity.combined(with: .offset(x: CGFloat(-tabSlideDirection) * 28))
            )
        )
    }

    @ViewBuilder
    private var feedBodyContent: some View {
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
            HomeFeedTabGenericEmpty(tab: viewModel.selectedFeedTab)
        } else {
            VStack(spacing: 0) {
                ListingStaggeredMasonryView(
                    items: viewModel.items,
                    columnAssignments: masonryColumnAssignments
                ) { item, index in
                    HomeFeedListingCell(
                        item: item,
                        index: index,
                        totalCount: viewModel.items.count,
                        surface: analyticsSurface,
                        imageAspectRatio: ListingMasonryGrid.masonryAspectRatio(for: item),
                        canPrefetchLoadMore: viewModel.selectedFeedTab == .following && viewModel.followingHasMore,
                        onPrefetchLoadMore: {
                            viewModel.loadMoreFollowing(deps: deps, isGuestMode: isGuestMode)
                        },
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
                            if isGuestMode {
                                onRequestSignIn(L10n.guestLoginReasonLike)
                            } else {
                                viewModel.toggleLike(
                                    item,
                                    surface: analyticsSurface,
                                    position: index,
                                    deps: deps
                                )
                            }
                        },
                        onSave: {
                            if isGuestMode {
                                onRequestSignIn(L10n.guestLoginReasonSaved)
                            } else {
                                viewModel.toggleSave(
                                    item,
                                    surface: analyticsSurface,
                                    position: index,
                                    deps: deps,
                                    isGuestMode: isGuestMode
                                )
                            }
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

                if viewModel.selectedFeedTab == .following,
                   viewModel.followingHasMore || viewModel.isLoadingMoreFollowing {
                    FeedLoadMoreFooter(
                        enabled: viewModel.followingHasMore,
                        isLoadingMore: viewModel.isLoadingMoreFollowing
                    ) {
                        viewModel.loadMoreFollowing(deps: deps, isGuestMode: isGuestMode)
                    }
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

    private func applyPinnedFeedScroll(using scrollProxy: ScrollViewProxy) {
        HomeFeedScrollReset.scrollToPinnedFeed(
            scrollPosition: $homeScrollPosition,
            proxy: scrollProxy,
            resetToken: $homeScrollResetToken,
            clampRevision: $scrollClampRevision
        )
    }

    private func scrollHomeToTop(using scrollProxy: ScrollViewProxy) {
        HomeFeedScrollReset.scrollToTop(
            scrollPosition: $homeScrollPosition,
            proxy: scrollProxy,
            resetToken: $homeScrollResetToken,
            clampRevision: $scrollClampRevision
        )
    }
}

private struct HomeFeedListingCell: View {
    let item: ListingFeedItem
    let index: Int
    let totalCount: Int
    let surface: String
    let imageAspectRatio: CGFloat
    var canPrefetchLoadMore: Bool = false
    var onPrefetchLoadMore: () -> Void = {}
    let onTap: () -> Void
    let onLike: () -> Void
    var onSave: (() -> Void)? = nil
    let onRecordView: () -> Void
    let onDwell: (Int) -> Void

    @State private var appearedAt: Date?
    @State private var recordViewTask: Task<Void, Never>?

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
            recordViewTask?.cancel()
            recordViewTask = Task {
                try? await Task.sleep(for: .milliseconds(450))
                guard !Task.isCancelled else { return }
                onRecordView()
            }
            if canPrefetchLoadMore,
               FeedPaginationPolicy.shouldPrefetchNextPage(
                   appearedIndex: index,
                   totalCount: totalCount
               ) {
                onPrefetchLoadMore()
            }
        }
        .onDisappear {
            recordViewTask?.cancel()
            recordViewTask = nil
            if let appearedAt {
                let dwellMs = Int(Date().timeIntervalSince(appearedAt) * 1_000)
                onDwell(dwellMs)
            }
            self.appearedAt = nil
        }
    }
}
