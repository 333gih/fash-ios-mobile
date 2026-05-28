import SwiftUI

struct ExploreScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    @Bindable var listingPreview: ListingPreviewStore
    var isGuestMode: Bool
    var hideInlineSearch: Bool = false
    var promoSlides: [FashPromoSlideDef] = []
    var onPromoSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }
    var onFeaturedSellerClick: (UserSearchResult) -> Void = { _ in }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

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
        HStack(spacing: spacing.spacing2) {
            sectionButton(L10n.exploreSectionListings, .listings)
            sectionButton(L10n.exploreSectionSellers, .sellers)
            Spacer()
            if viewModel.isSearchModeActive {
                Button(L10n.exploreSearchClearActive) {
                    Task { await viewModel.clearListingSearch(deps: deps, isGuestMode: isGuestMode) }
                }
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.brandPrimary)
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.top, spacing.spacing2)
    }

    private func sectionButton(_ title: String, _ section: ExplorePrimarySection) -> some View {
        let selected = viewModel.primarySection == section
        return Button {
            Task { await viewModel.setPrimarySection(section, deps: deps, isGuestMode: isGuestMode) }
        } label: {
            Text(title)
                .font(FashTypography.labelLarge)
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? FashColors.surfaceContainerHigh : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var filterBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.exploreFiltersBarTitle)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.textPrimary)
                Text(viewModel.hasActiveFilters || viewModel.isSearchModeActive
                     ? L10n.exploreFiltersBarSubtitleActive
                     : L10n.exploreFiltersBarSubtitleIdle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            Spacer()
            Button {
                viewModel.showFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(FashColors.textPrimary)
            }
            if viewModel.hasActiveFilters {
                Button(L10n.exploreFiltersClear) {
                    Task { await viewModel.clearAllFilters(deps: deps, isGuestMode: isGuestMode) }
                }
                .font(FashTypography.labelMedium)
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, spacing.spacing2)
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
            LazyVStack(spacing: 12) {
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
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                            ListingGridCard(item: item) {
                                listingPreview.open(
                                    item: item,
                                    deps: deps,
                                    publicBrowse: isGuestMode,
                                    surface: "explore",
                                    position: index
                                )
                            }
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

/// Bottom-docked promo chrome — Android `StickyBottomPromoBar`.
struct StickyBottomPromoBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.35)
            content()
        }
        .frame(maxWidth: .infinity)
        .background(FashColors.surfaceContainerLow)
    }
}

/// Space reserved above bottom nav / tab bar for sticky promo slider.
let FashStickyPromoDockHeight: CGFloat = 128
