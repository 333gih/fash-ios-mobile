import SwiftUI

struct ExploreScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var hideInlineSearch: Bool = false
    var promoSlides: [FashPromoSlideDef] = []
    var onPromoSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }
    var onFeaturedSellerClick: (UserSearchResult) -> Void = { _ in }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    private let gridSpacing: CGFloat = 8

    private var promoDockInset: CGFloat {
        promoSlides.isEmpty ? 0 : FashStickyPromoDockHeight
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if !hideInlineSearch {
                    searchRow
                }
                if viewModel.searchBarExpanded && !viewModel.isSearchModeActive {
                    ExploreSearchOverlay(viewModel: viewModel, isGuestMode: isGuestMode)
                        .frame(maxHeight: .infinity)
                } else {
                    sectionToggle
                    filterBar
                    content
                }
            }
            if !promoSlides.isEmpty, !(viewModel.searchBarExpanded && !viewModel.isSearchModeActive) {
                StickyBottomPromoBar {
                    FashPromoSliderView(
                        slides: promoSlides,
                        cardHeight: 112,
                        onSlideClick: onPromoSlideClick
                    )
                }
            }
        }
        .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            ExploreFilterSheet(viewModel: viewModel, isGuestMode: isGuestMode) {
                viewModel.showFilterSheet = false
            }
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

    private var sectionToggle: some View {
        VStack(spacing: spacing.spacing2) {
            ExplorePrimarySectionSwitcher(selected: viewModel.primarySection) { section in
                Task { await viewModel.setPrimarySection(section, deps: deps, isGuestMode: isGuestMode) }
            }
            .padding(.horizontal, spacing.editorialStart)

            if viewModel.isSearchModeActive {
                HStack {
                    Spacer()
                    Button(L10n.exploreSearchClearActive) {
                        Task { await viewModel.clearListingSearch(deps: deps, isGuestMode: isGuestMode) }
                    }
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.brandPrimary)
                }
                .padding(.horizontal, spacing.editorialStart)
            }
        }
        .padding(.top, spacing.spacing2)
    }

    @ViewBuilder
    private var filterBar: some View {
        if viewModel.primarySection == .listings {
            ExploreFiltersBar(
                hasActiveFilters: viewModel.hasActiveFilters,
                filterSummaryParts: viewModel.filterSummaryParts,
                isSearchMode: viewModel.isSearchModeActive,
                onOpenFilters: { viewModel.showFilterSheet = true },
                onClearFilters: viewModel.hasActiveFilters ? {
                    Task { await viewModel.clearAllFilters(deps: deps, isGuestMode: isGuestMode) }
                } : nil
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.primarySection == .listings {
            ExploreCategoryStrip(
                roots: viewModel.categoryTree,
                selectedId: viewModel.selectedCategoryId
            ) { node in
                viewModel.selectedCategoryId = node?.id
                viewModel.selectedCategoryName = node?.name
                Task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
            }
            listingsGrid
        } else {
            sellersList
        }
    }

    private var listingsGrid: some View {
        ScrollView {
            LazyVStack(spacing: gridSpacing) {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    FashSkeleton.listingGrid()
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
                    LazyVGrid(columns: columns, spacing: gridSpacing) {
                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                            ListingGridCard(
                                item: item,
                                onTap: {
                                    deps.presentListingPreview(
                                        item: item,
                                        router: router,
                                        publicBrowse: isGuestMode,
                                        surface: "explore",
                                        position: index
                                    )
                                },
                                showQuickActions: true,
                                onLike: {
                                    if isGuestMode {
                                        // Guest gate handled at tab level; like requires login on Android too
                                    } else {
                                        Task { await viewModel.toggleLike(item, deps: deps) }
                                    }
                                },
                                onSave: {
                                    if !isGuestMode {
                                        Task { await viewModel.toggleSave(item, deps: deps) }
                                    }
                                }
                            )
                            .onAppear {
                                if index >= viewModel.items.count - 3 {
                                    Task { await viewModel.loadMore(deps: deps, isGuestMode: isGuestMode) }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, spacing.editorialStart)
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    HomeBrandFooterStrip()
                }
            }
            .padding(.top, spacing.spacing2)
            .padding(.bottom, promoDockInset + spacing.spacing4)
        }
    }

    private var sellersList: some View {
        ScrollView {
            if viewModel.sellerResults.isEmpty {
                FashEmptyStateView(title: L10n.searchPlaceholder, subtitle: L10n.feedEmptySubtitle)
                    .padding()
            } else {
                LazyVStack(spacing: spacing.spacing3) {
                    ForEach(viewModel.sellerResults) { seller in
                        Button {
                            onFeaturedSellerClick(seller)
                        } label: {
                            HStack(spacing: spacing.spacing3) {
                                FashAvatarCircle(url: seller.avatarUrl, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(seller.displayName.isEmpty ? seller.username : seller.displayName)
                                        .font(FashTypography.labelLarge)
                                        .foregroundStyle(FashColors.textPrimary)
                                    if !seller.username.isEmpty {
                                        Text("@\(seller.username)")
                                            .font(FashTypography.bodySmall)
                                            .foregroundStyle(FashColors.textSecondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, spacing.editorialStart)
                        }
                        .buttonStyle(.plain)
                    }
                    HomeBrandFooterStrip()
                }
                .padding(.vertical, spacing.spacing4)
                .padding(.bottom, promoDockInset)
            }
        }
    }
}
