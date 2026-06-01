import SwiftUI

/// Identifiable wrapper for PDP `fullScreenCover` while Explore overlay is open.
private struct ExploreListingDetailCover: Identifiable {
    let id: String
}

/// Full-screen Explore from Home search — Android `ExploreOverlayHost`.
struct ExploreOverlayHost: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var expandSearchOnAppear: Bool = false
    var promoSlides: [FashPromoSlideDef] = []
    var onClose: () -> Void
    var onRequestSignIn: ((String) -> Void)? = nil

    @State private var topBarCompact = false
    @State private var showPinnedMarketplaceChrome = false
    @State private var headerScrollMinY: CGFloat = 0
    @State private var marketplaceControlsMaxY: CGFloat = .infinity

    var body: some View {
        @Bindable var listingPreview = deps.listingPreview
        VStack(spacing: 0) {
            ExploreTopBar(
                viewModel: viewModel,
                isGuestMode: isGuestMode,
                animateSearchIcon: true,
                compact: topBarCompact,
                onCloseOverlay: onClose
            )
            if showPinnedMarketplaceChrome {
                ExploreStickyChrome(
                    viewModel: viewModel,
                    isGuestMode: isGuestMode,
                    deps: deps
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            ExploreScreen(
                viewModel: viewModel,
                router: router,
                isGuestMode: isGuestMode,
                hideInlineSearch: true,
                openListingAsFullScreen: false,
                promoSlides: promoSlides,
                onPromoSlideClick: { slide, index in router.handlePromoSlideClick(slide) },
                onFeaturedSellerClick: { seller in
                    let username = seller.username.trimmingCharacters(in: .whitespaces)
                    guard !username.isEmpty else { return }
                    deps.navigateFromListingPreview(router: router) {
                        router.sellerShopUsername = username
                    }
                },
                onSeeAllFeaturedSellers: {
                    onClose()
                    router.showFeaturedSellersAll = true
                },
                onRequestSignIn: onRequestSignIn,
                hostManagesStickyChrome: true
            )
        }
        .background(FashColors.screen)
        .animation(.easeInOut(duration: 0.22), value: showPinnedMarketplaceChrome)
        .onPreferenceChange(ExploreHeaderScrollKey.self) { headerScrollMinY = $0; syncScrollChrome() }
        .onPreferenceChange(ExploreMarketplaceControlsScrollKey.self) {
            marketplaceControlsMaxY = $0
            syncScrollChrome()
        }
        .overlay(alignment: .bottom) {
            ListingPreviewOverlay(
                listingPreview: listingPreview,
                router: router,
                isGuestMode: isGuestMode,
                onRequestLogin: { onRequestSignIn?(L10n.guestLoginReasonBuy) },
                onFeedEngagementPatch: { id, transform in
                    viewModel.patchListingEngagement(id, transform: transform)
                }
            )
            .zIndex(20)
        }
        .fullScreenCover(item: exploreListingCoverBinding) { cover in
            FashProductDetailRouteView(
                router: router,
                listingId: cover.id,
                isGuestMode: isGuestMode,
                dismissExploreOverlayOnClose: false
            )
        }
        .onAppear {
            topBarCompact = false
            showPinnedMarketplaceChrome = false
            headerScrollMinY = 0
            marketplaceControlsMaxY = .infinity
            deps.listingPreview.close(deps: deps)
        }
        .task {
            if expandSearchOnAppear {
                viewModel.requestSearchBarExpanded()
                await viewModel.loadSearchOverlayData(deps: deps)
            }
            await viewModel.loadFilterCatalogIfNeeded(deps: deps)
            await viewModel.onExploreOpened(deps: deps, isGuestMode: isGuestMode)
        }
    }

    private var exploreListingCoverBinding: Binding<ExploreListingDetailCover?> {
        Binding(
            get: {
                guard let id = router.exploreOverlayListingId else { return nil }
                return ExploreListingDetailCover(id: id)
            },
            set: { router.selectedListingId = $0?.id }
        )
    }

    private func syncScrollChrome() {
        let hasSellerSearch = !viewModel.committedSellerSearchQuery
            .trimmingCharacters(in: .whitespaces).isEmpty
        let nextPinned = ExploreStickyChromePolicy.shouldPinMarketplaceChrome(
            currentlyShown: showPinnedMarketplaceChrome,
            headerMinY: headerScrollMinY,
            controlsMaxY: marketplaceControlsMaxY,
            primarySection: viewModel.primarySection,
            hasSellerSearch: hasSellerSearch
        )
        let nextCompact = ExploreStickyChromePolicy.shouldCompactTopBar(
            currentlyShown: topBarCompact,
            headerMinY: headerScrollMinY,
            controlsMaxY: marketplaceControlsMaxY
        )
        guard showPinnedMarketplaceChrome != nextPinned || topBarCompact != nextCompact else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            showPinnedMarketplaceChrome = nextPinned
            topBarCompact = nextCompact
        }
    }
}
