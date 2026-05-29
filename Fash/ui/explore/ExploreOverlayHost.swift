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

    var body: some View {
        VStack(spacing: 0) {
            ExploreTopBar(
                viewModel: viewModel,
                isGuestMode: isGuestMode,
                animateSearchIcon: true,
                onCloseOverlay: onClose
            )
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
                }
            )
        }
        .background(FashColors.screen)
        .overlay(alignment: .bottom) {
            ListingPreviewOverlay(
                listingPreview: deps.listingPreview,
                router: router,
                isGuestMode: isGuestMode,
                onRequestLogin: { onRequestSignIn?(L10n.guestLoginReasonBuy) }
            )
        }
        .onAppear {
            deps.listingPreview.close(deps: deps)
        }
        .task {
            if expandSearchOnAppear {
                viewModel.requestSearchBarExpanded()
                await viewModel.loadSearchOverlayData(deps: deps)
            }
            await viewModel.loadFilterCatalogIfNeeded(deps: deps)
            if viewModel.items.isEmpty, !viewModel.isLoading {
                await viewModel.refresh(deps: deps, isGuestMode: isGuestMode)
            }
        }
    }
}
