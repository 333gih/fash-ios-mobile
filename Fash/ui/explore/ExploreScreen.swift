import SwiftUI

struct ExploreScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var hideInlineSearch: Bool = false
    /// When true, open PDP full screen; default uses bottom preview sheet like Home.
    var openListingAsFullScreen: Bool = false
    var promoSlides: [FashPromoSlideDef] = []
    var onPromoSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }
    var onFeaturedSellerClick: (UserSearchResult) -> Void = { _ in }
    var onSeeAllFeaturedSellers: () -> Void = {}
    var onRequestSignIn: ((String) -> Void)? = nil

    /// Host renders pinned chrome below [ExploreTopBar]; feed does not overlay it on the grid.
    var hostManagesStickyChrome: Bool = false

    @State private var showStickyChrome = false
    @State private var headerScrollMinY: CGFloat = 0
    @State private var marketplaceControlsMaxY: CGFloat = .infinity
    @State private var masonryColumnAssignments: [String: Bool] = [:]

    private var tabsFadeOpacity: CGFloat {
        ExploreTabsCollapse.fadeOpacity(headerMinY: headerScrollMinY)
    }

    /// Listings always show the filter row; sellers only when a search query is committed.
    private var showsStickyChromeOverlay: Bool {
        guard showStickyChrome else { return false }
        if viewModel.primarySection == .listings { return true }
        return !viewModel.committedSellerSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var promoDockInset: CGFloat {
        promoSlides.isEmpty ? 0 : FashStickyPromoDockHeight
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if viewModel.isLoading && viewModel.items.isEmpty && viewModel.primarySection == .listings && !viewModel.isSearchModeActive {
                FashSkeleton.listingGrid()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(FashColors.screen)
                    .zIndex(2)
            }

            if viewModel.searchBarExpanded {
                ExploreSearchOverlay(viewModel: viewModel, isGuestMode: isGuestMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.primarySection == .listings {
                listingsGrid
            } else {
                sellersDiscoveryColumn
            }

            if !hideInlineSearch {
                VStack {
                    searchRow
                    Spacer()
                }
                .zIndex(3)
            }

            if !promoSlides.isEmpty, !viewModel.searchBarExpanded {
                StickyBottomPromoBar(elevated: true) {
                    FashPromoSliderView(
                        slides: promoSlides,
                        onSlideClick: onPromoSlideClick
                    )
                }
            }
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            ExploreFilterSheet(viewModel: viewModel, isGuestMode: isGuestMode) {
                viewModel.showFilterSheet = false
            }
            .presentationDetents([.fraction(0.7)])
            .presentationDragIndicator(.visible)
        }
        .onPreferenceChange(ExploreHeaderScrollKey.self) { headerScrollMinY = $0; updateStickyChromeState() }
        .onPreferenceChange(ExploreMarketplaceControlsScrollKey.self) {
            marketplaceControlsMaxY = $0
            updateStickyChromeState()
        }
        .background {
            Color.clear.preference(
                key: ExploreStickyChromeVisibleKey.self,
                value: showsStickyChromeOverlay
            )
        }
        .onChange(of: viewModel.primarySection) { _, _ in
            showStickyChrome = false
            headerScrollMinY = 0
            marketplaceControlsMaxY = .infinity
        }
    }

    private func updateStickyChromeState() {
        let next = ExploreStickyChromePolicy.shouldPinMarketplaceChrome(
            currentlyShown: showStickyChrome,
            headerMinY: headerScrollMinY,
            controlsMaxY: marketplaceControlsMaxY,
            primarySection: viewModel.primarySection,
            hasSellerSearch: !viewModel.committedSellerSearchQuery
                .trimmingCharacters(in: .whitespaces).isEmpty
        )
        guard next != showStickyChrome else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            showStickyChrome = next
        }
    }

    private var searchRow: some View {
        TextField(L10n.searchPlaceholder, text: $viewModel.query)
            .font(FashTypography.bodyMedium)
            .padding(.horizontal, spacing.spacing4)
            .padding(.vertical, spacing.spacing3)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            .padding(.horizontal, spacing.editorialStart)
            .padding(.top, spacing.spacing2)
            .onSubmit { Task { await viewModel.submitSearch(deps: deps, isGuestMode: isGuestMode) } }
    }

    // MARK: - Expanded header (scrolls away; sticky compact chrome replaces it)

    /// Expanded chrome inside scroll — inline tabs/filters hide when sticky chrome is shown (Android `!showStickyExploreChrome`).
    private var listingsExpandedHeader: some View {
        VStack(spacing: spacing.spacing2) {
            if !showsStickyChromeOverlay {
                sectionToggle
                    .opacity(tabsFadeOpacity)
                    .animation(.easeInOut(duration: 0.22), value: tabsFadeOpacity)
                marketplaceControlsColumn
            }
            listingsLeadingRows
            ExploreCategoryStrip(
                roots: viewModel.categoryTree,
                selectedId: viewModel.categoryStripHighlightId
            ) { node in
                viewModel.selectedCategoryId = node?.id
                viewModel.selectedCategoryName = node?.name
                Task {
                    await viewModel.reloadListingsAfterFilterChange(deps: deps, isGuestMode: isGuestMode)
                }
            }
        }
    }

    private var sellersExpandedHeader: some View {
        VStack(spacing: spacing.spacing2) {
            if !showsStickyChromeOverlay {
                sectionToggle
                    .opacity(tabsFadeOpacity)
                    .animation(.easeInOut(duration: 0.22), value: tabsFadeOpacity)
                marketplaceControlsColumn
            }
        }
    }

    private var exploreStickyChromeHeader: some View {
        ExploreStickyChrome(
            viewModel: viewModel,
            isGuestMode: isGuestMode,
            deps: deps
        )
    }

    private var sectionToggle: some View {
        VStack(spacing: spacing.spacing2) {
            ExplorePrimarySectionSwitcher(selected: viewModel.primarySection) { section in
                Task { await viewModel.setPrimarySection(section, deps: deps, isGuestMode: isGuestMode) }
            }
            .padding(.horizontal, spacing.editorialStart)

        }
        .padding(.top, spacing.spacing2)
    }

    /// Filter + committed search (not tabs) — scroll position drives sticky chrome.
    @ViewBuilder
    private var marketplaceControlsColumn: some View {
        VStack(spacing: spacing.spacing2) {
            switch viewModel.primarySection {
            case .listings:
                if viewModel.isSearchModeActive {
                    ExploreActiveSearchQueryBanner(
                        query: viewModel.committedListingSearchQuery,
                        onClear: {
                            Task { await viewModel.clearListingSearch(deps: deps, isGuestMode: isGuestMode) }
                        }
                    )
                    .padding(.horizontal, spacing.editorialStart)
                }
                filterBar
            case .sellers:
                if !viewModel.committedSellerSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                    ExploreActiveSearchQueryBanner(
                        query: viewModel.committedSellerSearchQuery,
                        onClear: {
                            Task { await viewModel.clearSellerSearch(deps: deps, isGuestMode: isGuestMode) }
                        }
                    )
                    .padding(.horizontal, spacing.editorialStart)
                }
            }
        }
        .exploreMarketplaceControlsScrollReporting()
    }

    @ViewBuilder
    private var filterBar: some View {
        if viewModel.primarySection == .listings {
            ExploreFiltersBar(
                hasActiveFilters: viewModel.hasActiveFilters,
                filterSummaryParts: viewModel.filterSummaryParts,
                onOpenFilters: { viewModel.showFilterSheet = true },
                onClearFilters: viewModel.hasActiveFilters ? {
                    Task { await viewModel.clearAllFilters(deps: deps, isGuestMode: isGuestMode) }
                } : nil
            )
        }
    }

    private var listingsLeadingRows: some View {
        VStack(spacing: spacing.spacing2) {
            if viewModel.isSizingFilterActive || viewModel.shoppingContext?.chipLabel() != nil {
                ExploreActivePersonalFilterChips(
                    sizingActive: viewModel.isSizingFilterActive,
                    seasonContextLabel: viewModel.shoppingContext?.chipLabel(),
                    onClearSizing: {
                        viewModel.setSizingModeFilter(nil)
                        Task {
                            await viewModel.reloadListingsAfterFilterChange(deps: deps, isGuestMode: isGuestMode)
                        }
                    },
                    onOpenFilters: { viewModel.showFilterSheet = true }
                )
            }
            if !viewModel.quickInterestChips.isEmpty
                && !viewModel.hasActiveFilters
                && !viewModel.isSearchModeActive {
                ExploreInterestChipsRow(
                    chips: viewModel.quickInterestChips,
                    selectedChipNames: viewModel.selectedInterestChipNames
                ) { chip in
                    Task { await viewModel.toggleInterestChip(chip, deps: deps, isGuestMode: isGuestMode) }
                }
            }
        }
    }

    // MARK: - Listings feed

    private var listingsGrid: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ExploreFeedScrollOffsetAnchor()
                        .id(ExploreFeedScrollIds.top)

                    listingsExpandedHeader

                    listingsFeedContent
                }
                .padding(.bottom, promoDockInset + spacing.spacing4)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .onChange(of: viewModel.listingsScrollToTopToken) { _, _ in
                scrollExploreToTop(using: scrollProxy)
            }
            .onChange(of: viewModel.listingsFeedEpoch) { _, _ in
                masonryColumnAssignments = [:]
                scrollExploreToTop(using: scrollProxy)
            }
        }
        .background(FashColors.screen)
        .coordinateSpace(name: "exploreFeedScroll")
        .overlay(alignment: .top) {
            if !hostManagesStickyChrome, showsStickyChromeOverlay {
                exploreStickyChromeHeader
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .overlay {
            if viewModel.isReloadingListings, !viewModel.items.isEmpty, !viewModel.isRefreshing {
                FashSkeleton.listingGrid(rows: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, spacing.spacing8)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showsStickyChromeOverlay)
        .fashFeedPullRefresh(isRefreshing: $viewModel.isRefreshing) {
            masonryColumnAssignments = [:]
            await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode)
        }
    }

    private func scrollExploreToTop(using scrollProxy: ScrollViewProxy) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollProxy.scrollTo(ExploreFeedScrollIds.top, anchor: .top)
        }
    }

    @ViewBuilder
    private var listingsFeedContent: some View {
        if viewModel.isLoading, viewModel.items.isEmpty {
            FashSkeleton.listingGrid()
                .padding(.top, spacing.spacing2)
        } else if viewModel.loadError && viewModel.items.isEmpty {
            FashEmptyStateView(title: L10n.feedLoadError, actionTitle: L10n.feedRetry) {
                Task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
            }
        } else if viewModel.items.isEmpty {
            FashEmptyStateView(
                title: viewModel.hasActiveFilters || viewModel.isSearchModeActive
                    ? L10n.exploreEmptyFilteredTitle
                    : L10n.feedEmptyTitle,
                subtitle: L10n.feedEmptySubtitle
            )
        } else {
            ListingStaggeredMasonryView(
                items: viewModel.items,
                columnAssignments: $masonryColumnAssignments
            ) {
                VStack(spacing: spacing.spacing2) {
                    if viewModel.hasMore || viewModel.isLoadingMore {
                        FeedLoadMoreFooter(
                            enabled: viewModel.hasMore,
                            isLoadingMore: viewModel.isLoadingMore
                        ) {
                            viewModel.requestLoadMore(deps: deps, isGuestMode: isGuestMode)
                        }
                    }
                    if !viewModel.hasMore {
                        HomeBrandFooterStrip()
                    }
                }
            } cellContent: { item, index in
                ExploreListingCell(
                    item: item,
                    index: index,
                    isGuestMode: isGuestMode,
                    openListingAsFullScreen: openListingAsFullScreen,
                    viewModel: viewModel,
                    router: router,
                    deps: deps
                )
            }
            .id(viewModel.listingsFeedEpoch)
            .padding(.top, spacing.spacing2)
        }
    }

    // MARK: - Sellers feed

    private var sellersDiscoveryColumn: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: spacing.spacing3) {
                ExploreFeedScrollOffsetAnchor()

                sellersExpandedHeader

                Text(L10n.exploreSellersSubtitle)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                    .padding(.horizontal, spacing.editorialStart)

                if !viewModel.featuredSellers.isEmpty {
                        ExploreFeaturedSellersSection(
                            sellers: viewModel.featuredSellers,
                            onSellerClick: { seller in onFeaturedSellerClick(seller.toUserSearchResult()) },
                            onSeeAllClick: onSeeAllFeaturedSellers
                        )
                        .padding(.horizontal, spacing.editorialStart)
                }

                if viewModel.sellersLoading && viewModel.sellerResults.isEmpty {
                        FashSkeleton.box(height: 132, cornerRadius: spacing.radiusSoftMin)
                            .padding(.horizontal, spacing.editorialStart)
                        ForEach(0..<4, id: \.self) { _ in
                            FashSkeleton.box(height: 220, cornerRadius: spacing.radiusSoftMin)
                                .padding(.horizontal, spacing.editorialStart)
                        }
                } else if viewModel.sellersLoadError && viewModel.sellerResults.isEmpty {
                        FashEmptyStateView(title: L10n.feedLoadError, actionTitle: L10n.feedRetry) {
                            Task { await viewModel.retrySellerBrowse(deps: deps, isGuestMode: isGuestMode) }
                        }
                        .padding(.horizontal, spacing.editorialStart)
                } else if !viewModel.sellersLoading && viewModel.sellerResults.isEmpty {
                        FashEmptyStateView(
                            title: L10n.exploreSellersEmpty,
                            subtitle: L10n.exploreSellersSearchPlaceholder
                        )
                        .padding(.horizontal, spacing.editorialStart)
                } else {
                    ForEach(viewModel.sellerResults) { seller in
                            let storeKey = seller.userId.trimmingCharacters(in: .whitespaces).isEmpty
                                ? seller.username.trimmingCharacters(in: .whitespaces)
                                : seller.userId.trimmingCharacters(in: .whitespaces)
                            ExploreSellerTikTokCard(
                                user: seller,
                                previewPosts: viewModel.sellerPreviewPosts[storeKey],
                                onSellerClick: { onFeaturedSellerClick(seller) },
                                onListingClick: { item in
                                    deps.presentListingPreview(
                                        item: item,
                                        router: router,
                                        publicBrowse: isGuestMode,
                                        surface: "explore_seller_preview",
                                        position: 0
                                    )
                                }
                            )
                            .padding(.horizontal, spacing.editorialStart)
                    }
                    HomeBrandFooterStrip()
                }
            }
            .padding(.bottom, promoDockInset + spacing.spacing4)
        }
        .background(FashColors.screen)
        .coordinateSpace(name: "exploreFeedScroll")
        .overlay(alignment: .top) {
            if !hostManagesStickyChrome, showsStickyChromeOverlay {
                exploreStickyChromeHeader
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showsStickyChromeOverlay)
        .fashFeedPullRefresh(isRefreshing: $viewModel.isRefreshing) {
            await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode)
        }
    }
}

private enum ExploreFeedScrollIds {
    static let top = "explore_feed_scroll_top"
}

private struct ExploreListingCell: View {
    let item: ListingFeedItem
    let index: Int
    let isGuestMode: Bool
    var openListingAsFullScreen: Bool = false
    @Bindable var viewModel: ExploreViewModel
    @Bindable var router: AppRouter
    let deps: AppDependencies
    var onRequestSignIn: ((String) -> Void)? = nil

    @State private var appearedAt: Date?

    var body: some View {
        ListingGridCard(
            item: item,
            onTap: {
                viewModel.reportListingClick(item: item, position: index, deps: deps)
                if openListingAsFullScreen {
                    deps.presentListingDetail(listingId: item.id, router: router)
                } else {
                    deps.presentListingPreview(
                        item: item,
                        router: router,
                        publicBrowse: isGuestMode,
                        surface: "explore",
                        position: index
                    )
                }
            },
            imageAspectRatio: ListingMasonryGrid.tileAspectWidthOverHeight(for: item),
            showQuickActions: true,
            statusOverlayLabel: ListingStatusUi.overlayLabel(for: item.listingStatus, suppressActive: true),
            onLike: {
                if isGuestMode {
                    onRequestSignIn?(L10n.guestLoginReasonLike)
                } else {
                    Task { await viewModel.toggleLike(item, position: index, deps: deps) }
                }
            },
            onSave: {
                if isGuestMode {
                    onRequestSignIn?(L10n.guestLoginReasonSaved)
                } else {
                    Task { await viewModel.toggleSave(item, position: index, deps: deps) }
                }
            }
        )
        .onAppear {
            appearedAt = Date()
            viewModel.recordView(item: item, position: index, deps: deps)
            if !viewModel.isRefreshing,
               !viewModel.isReloadingListings,
               FeedPaginationPolicy.shouldPrefetchNextPage(
                   appearedIndex: index,
                   totalCount: viewModel.items.count
               ) {
                viewModel.requestLoadMore(deps: deps, isGuestMode: isGuestMode)
            }
        }
        .onDisappear {
            if let appearedAt {
                let dwellMs = Int(Date().timeIntervalSince(appearedAt) * 1_000)
                viewModel.recordDwell(item: item, position: index, dwellMs: dwellMs, deps: deps)
            }
            self.appearedAt = nil
        }
    }
}
