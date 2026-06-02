import SwiftUI

/// Shared product detail full-screen — used from RootView and Explore overlay stack.
struct FashProductDetailRouteView: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    let listingId: String
    var isGuestMode: Bool
    /// When true, closing the entire PDP flow also dismisses the Explore overlay.
    var dismissExploreOverlayOnClose: Bool = false
    var onDismiss: () -> Void = {}
    var onListingClick: (String) -> Void = { _ in }
    var onDismissEntireFlow: () -> Void = {}

    var body: some View {
        ProductDetailScreen(
            listingId: listingId,
            isGuestMode: isGuestMode,
            onDismiss: onDismiss,
            onBuyNow: { router.selectedCheckoutListingId = $0 },
            onContinueOrder: { orderId in
                onDismissEntireFlow()
                router.selectedOrderId = orderId
            },
            onChat: { convId in
                onDismissEntireFlow()
                router.selectedConversationId = convId
            },
            onShare: { _, _ in },
            onListingClick: onListingClick,
            onVisitSellerShop: { username in
                deps.openSellerShop(username: username, router: router)
            },
            showTopBar: false,
            onRequestLogin: { router.loginStep = .email },
            onNavigateToExplore: { cat, brand, tag, query, countryId, iso in
                onDismissEntireFlow()
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
}
