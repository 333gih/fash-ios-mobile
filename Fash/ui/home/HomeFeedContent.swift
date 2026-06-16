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

    /// Skeleton min-height only when the active tab has no cached rows yet.
    private var homeFeedMinHeight: CGFloat {
        if !viewModel.items.isEmpty { return 0 }
        if viewModel.hasCachedItems(for: viewModel.selectedFeedTab) { return 0 }
        if viewModel.isRefreshing { return 0 }
        if viewModel.isShellLoading || viewModel.isTabLoading(viewModel.selectedFeedTab) {
            return 360
        }
        return 0
    }

    @State private var showStickyTabs = false
    @State private var chromePinnedLatch = false
    @State private var stickyScrollSample = HomeStickyScrollSample()
    @State private var homeScrollBoundary = HomeFeedScrollBoundary()
    @State private var homeHeaderHeight: CGFloat = 0
    @State private var homeTabRowHeight: CGFloat = 48
    @State private var feedContentBottomY: CGFloat = .infinity
    @State private var scrollViewportHeight: CGFloat = 0
    @State private var lastFollowingLoadMoreAt = Date.distantPast
    @State private var homeScrollClampRevision = 0
    @State private var masonryColumnAssignmentsByTab: [String: [String: Bool]] = [:]
    @State private var listingInteractionEnabled = true

    /// Sticky overlay — hysteresis latch avoids rubber-band flicker (Profile parity).
    private func recomputeStickyTabs() {
        let topMinY = stickyScrollSample.topMinY
        let tabRowMinY = stickyScrollSample.tabRowMinY

        // Full header visible — hide sticky copy (bottom-nav re-tap lands here too).
        if topMinY > -12 {
            if chromePinnedLatch || showStickyTabs {
                chromePinnedLatch = false
                showStickyTabs = false
            }
            return
        }

        guard tabRowMinY.isFinite else { return }

        // In-scroll tab row scrolled off — show Android-style pinned strip (tab row not visible).
        if tabRowMinY < -6 {
            chromePinnedLatch = true
        } else if chromePinnedLatch, tabRowMinY >= -2 {
            chromePinnedLatch = false
        }

        let shouldShow = chromePinnedLatch
        if showStickyTabs != shouldShow {
            showStickyTabs = shouldShow
        }
    }

    private var pinnedChromeHeight: CGFloat {
        max(0, homeHeaderHeight + homeTabRowHeight)
    }

    private var homeViewportHeightReader: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    if geo.size.height > 0 { scrollViewportHeight = geo.size.height }
                }
                .onChange(of: geo.size.height) { _, height in
                    if height > 0 { scrollViewportHeight = height }
                }
        }
    }

    private var masonryColumnWidth: CGFloat {
        ListingMasonryGrid.feedGridColumnWidth(
            containerWidth: UIScreen.main.bounds.width,
            spacing: spacing
        )
    }

    private var masonryColumnAssignments: Binding<[String: Bool]> {
        Binding(
            get: { masonryColumnAssignmentsByTab[viewModel.selectedFeedTabKey] ?? [:] },
            set: { masonryColumnAssignmentsByTab[viewModel.selectedFeedTabKey] = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { scrollProxy in
                ZStack(alignment: .top) {
                    ScrollView {
                        // VStack (not LazyVStack) — lazy-unloaded header/tabs shrink contentSize when
                        // pinned, which blocks scrolling back up until many drag attempts.
                        VStack(spacing: 0) {
                            homeScrollAwayHeader

                            homeFeedTabsBar(sticky: false)
                                .id(HomeScrollIds.pinnedTabs)
                                .homeTabRowScrollReporting()

                            feedBodyContent
                                .id(HomeScrollIds.feedContent)
                                .allowsHitTesting(listingInteractionEnabled)
                                .frame(minHeight: homeFeedMinHeight, alignment: .top)
                        }
                        .padding(.bottom, promoDockInset + spacing.spacing2)
                        .fashScrollViewTabSwipe(
                            currentIndex: selectedTabIndex,
                            tabCount: tabs.count,
                            listingInteractionEnabled: $listingInteractionEnabled,
                            onHorizontalSwipeActive: { active in
                                if active {
                                    deps.listingPreview.close(deps: deps, animated: false)
                                }
                            }
                        ) { index in
                            viewModel.selectFeedTab(tabs[index], deps: deps, isGuestMode: isGuestMode)
                        }
                        .background {
                            homeViewportHeightReader
                            PinnedTabScrollOffsetFixer(
                                trueTopToken: viewModel.homeScrollToTopToken,
                                clampRevision: homeScrollClampRevision,
                                headerHeight: pinnedChromeHeight,
                                suspendDuringPull: viewModel.isRefreshing
                            )
                            HomeFeedScrollCoordinator(
                                scrollBoundary: homeScrollBoundary,
                                scrollToTopToken: viewModel.homeScrollToTopToken
                            )
                            FeedScrollTrimCompensator(
                                token: viewModel.homeFeedTrimToken,
                                signedDeltaY: viewModel.homeFeedTrimSignedDeltaY
                            )
                        }
                    }
                    .coordinateSpace(name: "homeFeedScroll")

                    if showStickyTabs {
                        homeFeedTabsBar(sticky: true)
                            .zIndex(20)
                            .transition(.opacity)
                    }
                }
                .onPreferenceChange(HomeFeedScrollOffsetKey.self) { topMinY in
                    stickyScrollSample.topMinY = topMinY
                    recomputeStickyTabs()
                    evaluateFollowingScrollLoadMore(headerMinY: topMinY)
                }
                .onPreferenceChange(HomeTabRowMinYKey.self) { tabRowMinY in
                    stickyScrollSample.tabRowMinY = tabRowMinY
                    recomputeStickyTabs()
                }
                .onPreferenceChange(HomeTabRowHeightKey.self) { height in
                    guard height > 1, abs(height - homeTabRowHeight) > 0.5 else { return }
                    homeTabRowHeight = height
                }
                .onPreferenceChange(FeedContentBottomYKey.self) { bottomY in
                    feedContentBottomY = bottomY
                }
                .animation(.easeInOut(duration: 0.14), value: showStickyTabs)
                .fashFeedPullRefresh(isRefreshing: $viewModel.isRefreshing) {
                    await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode)
                }
                .onChange(of: viewModel.homeScrollToTopToken) { _, _ in
                    applyHomeScrollToTop(using: scrollProxy)
                }
                .onChange(of: viewModel.homeScrollToFeedTopToken) { _, _ in
                    applyHomeScrollToFeedTop(using: scrollProxy)
                }
                .onChange(of: viewModel.selectedFeedTabKey) { oldKey, newKey in
                    guard oldKey != newKey else { return }
                    onHomeFeedTabChanged(to: newKey)
                }
                .onChange(of: viewModel.items.count) { oldCount, newCount in
                    guard viewModel.selectedFeedTab == .following else { return }
                    guard newCount < oldCount, !viewModel.isRefreshing else { return }
                    homeScrollClampRevision += 1
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
        .task(id: viewModel.selectedFeedTabKey) {
            viewModel.ensureSelectedFeedTabLoaded(deps: deps, isGuestMode: isGuestMode)
        }
        .onAppear {
            viewModel.homeScrollBoundary = homeScrollBoundary
            viewModel.ensureSelectedFeedTabLoaded(deps: deps, isGuestMode: isGuestMode)
        }
        .onChange(of: isGuestMode) { _, guest in
            viewModel.normalizeSelectedFeedTab(isGuestMode: guest, deps: deps)
        }
    }

    @ViewBuilder
    private var homeScrollAwayHeader: some View {
        VStack(spacing: 0) {
            HomeFeedScrollOffsetAnchor()

            if let chip = viewModel.shoppingContextChip {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                    Text(chip)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(FashColors.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FashColors.surfaceContainerLow)
                .clipShape(Capsule())
                .padding(.bottom, 4)
            }

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
            } else if viewModel.featuredSellersLoading {
                HomeRecommendedSellersSkeleton()
            }

            if let exploreShortcut {
                HomeExploreShortcutBanner(
                    shortcut: exploreShortcut,
                    onClick: { onExploreShortcutClick(exploreShortcut) }
                )
            }
        }
        .homeFeedHeaderHeightReporting()
        .onHomeHeaderHeightChange($homeHeaderHeight)
    }

    /// Tab row — in-scroll copy; sticky overlay shown separately when scrolled off (Android parity).
    private func homeFeedTabsBar(sticky: Bool) -> some View {
        VStack(spacing: 0) {
            HomeFeedTabSwitcher(
                tabs: tabs,
                selectedTab: viewModel.selectedFeedTab,
                scrollToSelectedToken: viewModel.homeTabBarScrollToken,
                isGuestBrowse: isGuestMode,
                onSelect: { tab in
                    viewModel.selectFeedTab(tab, deps: deps, isGuestMode: isGuestMode)
                }
            )
            Divider()
                .overlay(FashColors.outlineMuted.opacity(0.35))
        }
        .background(FashColors.screen)
        .shadow(color: sticky ? Color.black.opacity(0.08) : .clear, radius: 3, y: 1)
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
        } else if viewModel.isTabLoadStalled(viewModel.selectedFeedTab), viewModel.items.isEmpty {
            FashEmptyStateView(
                title: L10n.feedLoadError,
                subtitle: L10n.feedLoadStallSubtitle,
                actionTitle: L10n.feedRetry
            ) {
                viewModel.retryTab(viewModel.selectedFeedTab, deps: deps, isGuestMode: isGuestMode)
            }
            .padding(.vertical, spacing.spacing4)
        } else if (viewModel.isShellLoading || viewModel.isTabLoading(viewModel.selectedFeedTab))
            && viewModel.items.isEmpty
            && !viewModel.hasCachedItems(for: viewModel.selectedFeedTab) {
            FashSkeleton.listingGrid()
                .padding(.top, spacing.spacing2)
        } else if viewModel.items.isEmpty {
            HomeFeedTabGenericEmpty(tab: viewModel.selectedFeedTab)
                .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            VStack(spacing: 0) {
                FeedMasonryChunkedGrid(
                    items: viewModel.items,
                    columnAssignments: masonryColumnAssignments,
                    footer: {
                        if viewModel.selectedFeedTab == .following,
                           viewModel.followingHasMore || viewModel.isLoadingMoreFollowing {
                            FeedLoadMoreFooter(
                                enabled: viewModel.followingHasMore,
                                isLoadingMore: viewModel.isLoadingMoreFollowing,
                                triggersLoadOnAppear: false,
                                rearmAfterLoadComplete: false
                            ) {
                                viewModel.loadMoreFollowing(deps: deps, isGuestMode: isGuestMode)
                            }
                        }
                    },
                    cell: { item, index in
                    HomeFeedListingCell(
                        item: item,
                        index: index,
                        surface: analyticsSurface,
                        imageAspectRatio: ListingMasonryGrid.masonryAspectRatio(for: item),
                        onPrefetchLoadMore: viewModel.selectedFeedTab == .following
                            ? {
                                viewModel.notifyFollowingCellVisible(
                                    index: index,
                                    columnWidth: masonryColumnWidth,
                                    deps: deps,
                                    isGuestMode: isGuestMode
                                )
                            }
                            : nil,
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
                )

                if viewModel.showsHomeBrandFooter(isGuestMode: isGuestMode) {
                    HomeBrandFooterStrip()
                }

                if !viewModel.items.isEmpty {
                    FeedScrollContentBottomReporter(coordinateSpace: "homeFeedScroll")
                }
            }
            .padding(.top, spacing.spacing2)
            .padding(.bottom, spacing.spacing4)
            .id(viewModel.selectedFeedTabKey)
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

    private func onHomeFeedTabChanged(to tabKey: String) {
        let tab = HomeFeedTab(rawValue: tabKey) ?? viewModel.selectedFeedTab
        viewModel.syncVisibleItemsForTab(tab)
        feedContentBottomY = .infinity
        lastFollowingLoadMoreAt = .distantPast
    }

    private func applyHomeScrollToTop(using scrollProxy: ScrollViewProxy) {
        chromePinnedLatch = false
        showStickyTabs = false
        HomeFeedScrollReset.scheduleScrollToTop(proxy: scrollProxy)
    }

    private func applyHomeScrollToFeedTop(using scrollProxy: ScrollViewProxy) {
        HomeFeedScrollReset.scheduleScrollToFeedTop(proxy: scrollProxy)
    }

    private func evaluateFollowingScrollLoadMore(headerMinY: CGFloat) {
        guard viewModel.selectedFeedTab == .following else { return }
        guard viewModel.followingHasMore, !viewModel.isLoadingMoreFollowing else { return }
        guard !viewModel.isShellLoading, !viewModel.isRefreshing else { return }
        guard !viewModel.isTabLoading(.following), !viewModel.items.isEmpty else { return }

        let now = Date()
        guard now.timeIntervalSince(lastFollowingLoadMoreAt) >= 0.65 else { return }

        let scrolled = max(0, -headerMinY)
        let minScroll = pinnedChromeHeight > 24
            ? max(pinnedChromeHeight * 0.25, 72)
            : 96
        guard scrolled > minScroll else { return }

        let shouldLoad = FeedScrollPaginationPolicy.shouldLoadMore(
            headerMinY: headerMinY,
            contentBottomY: feedContentBottomY,
            viewportHeight: scrollViewportHeight,
            hasItems: true,
            hasMore: viewModel.followingHasMore,
            isLoadingMore: viewModel.isLoadingMoreFollowing,
            isLoadingFirstPage: viewModel.isTabLoading(.following)
        ) || FeedScrollPaginationPolicy.isAtScrollBottom(
            headerMinY: headerMinY,
            contentBottomY: feedContentBottomY,
            viewportHeight: scrollViewportHeight,
            tolerance: 48
        )
        guard shouldLoad else { return }

        lastFollowingLoadMoreAt = now
        viewModel.loadMoreFollowing(deps: deps, isGuestMode: isGuestMode, fromScrollEdge: true)
    }
}

/// Non-observed scroll samples — mutating this does not re-render the feed on every scroll frame.
private final class HomeStickyScrollSample {
    var topMinY: CGFloat = 0
    var tabRowMinY: CGFloat = .infinity
}

private struct HomeFeedListingCell: View {
    let item: ListingFeedItem
    let index: Int
    let surface: String
    let imageAspectRatio: CGFloat
    var onPrefetchLoadMore: (() -> Void)? = nil
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
            statusOverlayLabel: ListingStatusUi.overlayLabel(for: item.listingStatus, suppressActive: true),
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
            onPrefetchLoadMore?()
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
