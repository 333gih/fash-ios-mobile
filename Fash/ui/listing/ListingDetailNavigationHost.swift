import SwiftUI

/// Product detail with in-flow push (related listings) — avoids dismissing/reopening fullScreenCover.
struct ListingDetailNavigationHost: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.fashSpacing) private var spacing
    @Bindable var router: AppRouter
    let rootListingId: String
    var isGuestMode: Bool
    var dismissExploreOverlayOnClose: Bool = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack(path: $router.listingDetailPath) {
                listingDetailPage(rootListingId)
                    .navigationDestination(for: String.self) { listingId in
                        listingDetailPage(listingId)
                    }
            }
            .toolbar(.hidden, for: .navigationBar)

            topBar
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: shareItems) { completed in
                FashActivityShare.showSuccessIfNeeded(
                    completed,
                    message: L10n.shareListingSuccess,
                    deps: deps
                )
            }
        }
    }

    private var currentListingId: String {
        router.listingDetailPath.last ?? rootListingId
    }

    private var topBar: some View {
        HStack {
            FashBackButton(action: { router.popListingDetail() })
            Spacer()
            Text(L10n.productDetailTitle)
                .font(FashTypography.titleSmall.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
            Spacer()
            Button(action: shareCurrentListing) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.leading, FashBackButton.leadingScreenInset)
        .padding(.trailing, 8)
        .padding(.top, spacing.spacing1)
        .background(FashColors.screen.opacity(0.92))
    }

    private func shareCurrentListing() {
        let listingId = currentListingId
        let web = AppEnvironment.listingShareURL(listingId: listingId)
        let fashUri = ListingDeepLinks.fashListingURL(listingId: listingId)?.absoluteString ?? ""
        let text = L10n.shareListingText(L10n.productDetailTitle, web, fashUri)
        shareItems = [L10n.shareListingSubject, text]
        showShareSheet = true
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
        .safeAreaPadding(.top, 56)
    }
}
