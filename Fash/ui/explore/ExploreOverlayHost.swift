import SwiftUI

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
    @State private var filterBarScrollMinY: CGFloat = .greatestFiniteMagnitude

    var body: some View {
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
                hostManagesStickyChrome: true
            )
        }
        .background(FashColors.screen)
        .animation(.easeInOut(duration: 0.22), value: showPinnedMarketplaceChrome)
        .onPreferenceChange(ExploreHeaderScrollKey.self) { headerScrollMinY = $0; updateTopBarCompact() }
        .onPreferenceChange(ExploreFilterBarScrollKey.self) { filterBarScrollMinY = $0; updateTopBarCompact() }
        .onPreferenceChange(ExploreStickyChromeVisibleKey.self) { visible in
            guard showPinnedMarketplaceChrome != visible else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                showPinnedMarketplaceChrome = visible
            }
        }
        .overlay(alignment: .bottom) {
            ListingPreviewOverlay(
                listingPreview: deps.listingPreview,
                router: router,
                isGuestMode: isGuestMode,
                onRequestLogin: { onRequestSignIn?(L10n.guestLoginReasonBuy) }
            )
        }
        .onAppear {
            topBarCompact = false
            showPinnedMarketplaceChrome = false
            headerScrollMinY = 0
            filterBarScrollMinY = .greatestFiniteMagnitude
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

    private func updateTopBarCompact() {
        let next = ExploreStickyChromePolicy.shouldCompactTopBar(
            currentlyShown: topBarCompact,
            headerMinY: headerScrollMinY,
            filterBarMinY: filterBarScrollMinY
        )
        guard topBarCompact != next else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            topBarCompact = next
        }
    }
}
