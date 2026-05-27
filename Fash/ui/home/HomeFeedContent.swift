import SwiftUI

struct HomeFeedContent: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: HomeViewModel
    @Bindable var listingPreview: ListingPreviewStore
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

    var body: some View {
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

                if !viewModel.promoSlides.isEmpty {
                    FashPromoSliderView(
                        slides: viewModel.promoSlides.map(FashPromoSlideDef.fromAdvertising)
                    )
                }

                HomeBrandFooterStrip()
            }
        }
        .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }
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
        case .forYou: return L10n.guestLoginReasonTopbar
        case .following: return L10n.guestLoginReasonTopbar
        case .stylePicks: return L10n.guestLoginReasonTopbar
        case .similarSaved: return L10n.guestLoginReasonTopbar
        default: return L10n.guestLoginSheetTitle
        }
    }
}
