import SwiftUI

/// Shared product detail full-screen — used from RootView and Explore overlay stack.
struct FashProductDetailRouteView: View {
    @Bindable var router: AppRouter
    let listingId: String
    var isGuestMode: Bool
    /// When true, closing PDP also dismisses the Explore overlay (e.g. opened from Khám phá).
    var dismissExploreOverlayOnClose: Bool = false

    var body: some View {
        ProductDetailScreen(
            listingId: listingId,
            isGuestMode: isGuestMode,
            onDismiss: dismissProductDetail,
            onBuyNow: { router.selectedCheckoutListingId = $0 },
            onContinueOrder: { orderId in
                dismissProductDetail()
                router.selectedOrderId = orderId
            },
            onChat: { convId in
                dismissProductDetail()
                router.selectedConversationId = convId
            },
            onShare: { _, _ in },
            onListingClick: { router.selectedListingId = $0 },
            onVisitSellerShop: { username in
                dismissProductDetail()
                router.sellerShopUsername = username
            },
            onRequestLogin: { router.loginStep = .email },
            onNavigateToExplore: { cat, brand, tag, query, countryId, iso in
                dismissProductDetail()
                router.pendingExploreProfileFilter = ExploreProfileFilterRequest(
                    categoryId: cat,
                    brandId: brand,
                    aestheticTagId: tag,
                    searchQuery: query,
                    countryId: countryId,
                    countryIso2: iso
                )
            }
        )
    }

    private func dismissProductDetail() {
        router.selectedListingId = nil
        if dismissExploreOverlayOnClose {
            router.showExploreOverlay = false
            router.exploreSearchExpanded = false
        }
    }
}
