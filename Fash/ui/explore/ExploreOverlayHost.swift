import SwiftUI

/// Full-screen Explore from Home search — Android `ExploreOverlayHost`.
struct ExploreOverlayHost: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    @Bindable var listingPreview: ListingPreviewStore
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var expandSearchOnAppear: Bool = false
    var promoSlides: [FashPromoSlideDef] = []
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ExploreTopBar(viewModel: viewModel, isGuestMode: isGuestMode, onCloseOverlay: onClose)
            ExploreScreen(
                viewModel: viewModel,
                listingPreview: listingPreview,
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
                }
            )
        }
        .background(FashColors.screen)
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
