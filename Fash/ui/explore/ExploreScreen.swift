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

    /// Host renders pinned chrome below [ExploreTopBar]; feed does not overlay it on the grid.
    var hostManagesStickyChrome: Bool = false

    @State private var showStickyChrome = false
    @State private var headerScrollMinY: CGFloat = 0
    @State private var marketplaceControlsMaxY: CGFloat = .infinity

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
                FashColors.screen
                    .overlay {
                        ProgressView()
                            .tint(FashColors.brandPrimary)
                            .scaleEffect(1.1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    /// Expanded chrome inside scroll — fades while scrolling; compact filters overlay via [ExploreStickyChrome].
    private var listingsExpandedHeader: some View {
        VStack(spacing: spacing.spacing2) {
            sectionToggle
                .opacity(tabsFadeOpacity)
                .animation(.easeInOut(duration: 0.22), value: tabsFadeOpacity)
            marketplaceControlsColumn
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
            sectionToggle
                .opacity(tabsFadeOpacity)
                .animation(.easeInOut(duration: 0.22), value: tabsFadeOpacity)
            marketplaceControlsColumn
        }
        .padding(.top, spacing.spacing2)
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
            if viewModel.isSizingFilterActive {
                ExploreActivePersonalFilterChips(
                    sizingActive: true,
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
        ScrollView {
            LazyVStack(spacing: 0) {
                ExploreFeedScrollOffsetAnchor()

                listingsExpandedHeader
                listingsFeedBody
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
        .overlay {
            if viewModel.isReloadingListings, !viewModel.items.isEmpty {
                ProgressView()
                    .tint(FashColors.brandPrimary)
                    .scaleEffect(1.05)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, spacing.spacing8)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showsStickyChromeOverlay)
        .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }
    }

    @ViewBuilder
    private var listingsFeedBody: some View {
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
            // Column masonry like Home / Android StaggeredGrid — tighter vertical rhythm than row-pair lazy rows.
            VStack(spacing: spacing.spacing4) {
                ListingMasonryGridView(items: viewModel.items) { item, index in
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

                ExploreListingsPaginationSentinel(
                    hasMore: viewModel.hasMore,
                    isLoadingMore: viewModel.isLoadingMore
                ) {
                    viewModel.requestLoadMore(deps: deps, isGuestMode: isGuestMode)
                }

                HomeBrandFooterStrip()
            }
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
        .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }
    }
}

/// Single prefetch trigger at the feed bottom — avoids duplicate `loadMore` from per-cell `onAppear`.
private struct ExploreListingsPaginationSentinel: View {
    let hasMore: Bool
    let isLoadingMore: Bool
    let onPrefetch: () -> Void

    private let triggerHeight: CGFloat = 96

    var body: some View {
        ZStack {
            Color.clear
                .frame(height: triggerHeight)
                .onAppear {
                    guard hasMore, !isLoadingMore else { return }
                    onPrefetch()
                }
            if isLoadingMore {
                ProgressView()
                    .tint(FashColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }
}

private struct ExploreListingCell: View {
    let item: ListingFeedItem
    let index: Int
    let isGuestMode: Bool
    var openListingAsFullScreen: Bool = false
    @Bindable var viewModel: ExploreViewModel
    @Bindable var router: AppRouter
    let deps: AppDependencies

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
            imageAspectRatio: ListingMasonryGrid.staggerAspectRatio(for: item.id),
            showQuickActions: true,
            onLike: {
                if !isGuestMode {
                    Task { await viewModel.toggleLike(item, position: index, deps: deps) }
                }
            },
            onSave: {
                if !isGuestMode {
                    Task { await viewModel.toggleSave(item, position: index, deps: deps) }
                }
            }
        )
        .onAppear {
            appearedAt = Date()
            viewModel.recordView(item: item, position: index, deps: deps)
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
