import SwiftUI

struct HomeFeedContent: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: HomeViewModel
    @Bindable var listingPreview: ListingPreviewStore
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var onOpenExplore: () -> Void = {}
    var onOpenPost: () -> Void = {}
    var onOpenOrders: () -> Void = {}
    var onOpenFeaturedSellersAll: () -> Void = {}
    var onFeaturedSellerClick: (FeaturedSellerItem) -> Void = { _ in }
    var onRequestSignIn: (String) -> Void = { _ in }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    private var tabs: [HomeFeedTab] {
        HomeFeedTab.tabsFor(isGuestBrowse: isGuestMode)
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

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    HomeQuickActionsRow(
                        onExplore: onOpenExplore,
                        onSell: onOpenPost,
                        onOrders: onOpenOrders,
                        compact: true
                    )

                    if !viewModel.featuredSellers.isEmpty {
                        HomeRecommendedSellersSection(
                            sellers: viewModel.featuredSellers,
                            onSellerClick: onFeaturedSellerClick,
                            onSeeAllClick: onOpenFeaturedSellersAll
                        )
                    }

                    HomeFeedTabSwitcher(
                        tabs: tabs,
                        selectedTab: viewModel.selectedFeedTab,
                        isGuestBrowse: isGuestMode,
                        onSelect: { tab in
                            viewModel.selectFeedTab(tab)
                            if isGuestMode && tab.requiresAuth {
                                return
                            }
                            Task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
                        }
                    )

                    feedBody

                    HomeBrandFooterStrip()
                }
                .padding(.bottom, promoDockInset + spacing.spacing2)
            }
            .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }

            if !promoSlides.isEmpty {
                StickyBottomPromoBar {
                    FashPromoSliderView(
                        slides: promoSlides,
                        cardHeight: 72,
                        onSlideClick: { slide, _ in router.handlePromoSlideClick(slide) }
                    )
                }
            }
        }
        .task {
            viewModel.normalizeSelectedFeedTab(isGuestMode: isGuestMode)
            await viewModel.refresh(deps: deps, isGuestMode: isGuestMode)
        }
        .onChange(of: isGuestMode) { _, guest in
            viewModel.normalizeSelectedFeedTab(isGuestMode: guest)
        }
    }

    @ViewBuilder
    private var feedBody: some View {
        if showGuestGate {
            HomeFeedTabGuestGate(tab: viewModel.selectedFeedTab) {
                onRequestSignIn(guestLoginReason(for: viewModel.selectedFeedTab))
            }
        } else if viewModel.isLoading && viewModel.items.isEmpty {
            FashSkeleton.listingGrid()
                .padding(.horizontal, spacing.editorialStart)
                .padding(.vertical, spacing.spacing4)
        } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
            FashEmptyStateView(
                title: L10n.feedLoadError,
                subtitle: error,
                actionTitle: L10n.feedRetry
            ) {
                Task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
            }
            .padding(.vertical, spacing.spacing4)
        } else if viewModel.items.isEmpty {
            HomeFeedTabGenericEmpty(tab: viewModel.selectedFeedTab)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    ListingGridCard(item: item) {
                        listingPreview.open(
                            item: item,
                            deps: deps,
                            publicBrowse: isGuestMode,
                            surface: viewModel.selectedFeedTab.rawValue,
                            position: index
                        )
                    }
                }
            }
            .padding(.leading, spacing.editorialStart)
            .padding(.trailing, spacing.editorialEnd)
            .padding(.vertical, spacing.spacing4)
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
