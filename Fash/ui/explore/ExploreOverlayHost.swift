import SwiftUI

/// Stable identity for PDP `fullScreenCover` while Explore is open (listing id changes via NavigationStack).
private enum ExploreListingDetailCover: Identifiable {
    case flow

    var id: String { "explore-listing-flow" }
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
    @State private var topBarCompact = false
    @State private var showGuestLoginSheet = false
    @State private var guestLoginReason: String?
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
                    deps.openSellerShop(username: username, router: router)
                },
                onSeeAllFeaturedSellers: {
                    onClose()
                    router.showFeaturedSellersAll = true
                },
                onRequestSignIn: isGuestMode ? presentGuestSignIn : nil,
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
                onRequestLogin: isGuestMode ? { presentGuestSignIn(L10n.guestLoginReasonBuy) } : nil
                onFeedEngagementPatch: { id, transform in
                    viewModel.patchListingEngagement(id, transform: transform)
                }
            )
            .zIndex(20)
        }
        .fullScreenCover(item: exploreListingCoverBinding) { _ in
            if let rootId = router.listingDetailRootId {
                ListingDetailNavigationHost(
                    router: router,
                    rootListingId: rootId,
                    isGuestMode: isGuestMode,
                    dismissExploreOverlayOnClose: false
                )
            }
        }
        .fashSnackbarOverlay()
        .guestLoginSheet(
            isPresented: $showGuestLoginSheet,
            reason: guestLoginReason,
            router: router
        )
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
                router.exploreOverlayListingId != nil ? .flow : nil
            },
            set: { newValue in
                if newValue == nil {
                    router.closeListingDetailFlow()
                }
            }
        )
    }

    private func presentGuestSignIn(reason: String) {
        guestLoginReason = reason
        showGuestLoginSheet = true
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
