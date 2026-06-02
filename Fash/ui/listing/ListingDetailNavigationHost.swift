import SwiftUI

/// Product detail with in-flow push (related listings) — avoids dismissing/reopening fullScreenCover.
struct ListingDetailNavigationHost: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    let rootListingId: String
    var isGuestMode: Bool
    var dismissExploreOverlayOnClose: Bool = false

    var body: some View {
        NavigationStack(path: $router.listingDetailPath) {
            listingDetailPage(rootListingId)
                .navigationDestination(for: String.self) { listingId in
                    listingDetailPage(listingId)
                }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func listingDetailPage(_ listingId: String) -> some View {
        FashProductDetailRouteView(
            router: router,
            listingId: listingId,
            isGuestMode: isGuestMode,
            dismissExploreOverlayOnClose: dismissExploreOverlayOnClose,
            onDismiss: { router.popListingDetail() },
            onListingClick: { router.pushListingDetail($0) },
            onDismissEntireFlow: { router.closeListingDetailFlow(dismissExplore: dismissExploreOverlayOnClose) }
        )
        .navigationBarBackButtonHidden(true)
    }
}
