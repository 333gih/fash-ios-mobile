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
            ExploreTopBar(viewModel: viewModel, isGuestMode: isGuestMode, onCloseOverlay: onClose)
            ExploreScreen(
                viewModel: viewModel,
                router: router,
                isGuestMode: isGuestMode,
                hideInlineSearch: true,
                promoSlides: promoSlides,
                onPromoSlideClick: { slide, index in router.handlePromoSlideClick(slide) },
                onFeaturedSellerClick: { seller in
                    let username = seller.username.trimmingCharacters(in: .whitespaces)
                    if !username.isEmpty {
                        onClose()
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
        .sheet(isPresented: Binding(
            get: { deps.listingPreview.state != nil },
            set: { presenting in
                if !presenting { deps.listingPreview.close(deps: deps) }
            }
        )) {
            ListingPreviewSheetHost(
                listingPreview: deps.listingPreview,
                router: router,
                isGuestMode: isGuestMode,
                onRequestLogin: { onRequestSignIn?(L10n.guestLoginReasonBuy) }
            )
        }
        .onChange(of: deps.listingPreview.state?.id) { _, _ in
            if let pending = router.pendingListingIdAfterPreview, deps.listingPreview.state == nil {
                router.pendingListingIdAfterPreview = nil
                onClose()
                DispatchQueue.main.async {
                    deps.presentListingDetail(listingId: pending, router: router)
                }
            }
        }
        .task {
            if expandSearchOnAppear {
                viewModel.requestSearchBarExpanded()
                await viewModel.loadSearchOverlayData(deps: deps)
            }
            await viewModel.loadFilterCatalogIfNeeded(deps: deps)
            await viewModel.refresh(deps: deps, isGuestMode: isGuestMode)
        }
    }
}
