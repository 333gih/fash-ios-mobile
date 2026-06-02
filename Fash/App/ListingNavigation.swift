import Foundation

extension AppDependencies {
    /// Opens listing quick-look without dismissing Explore overlay.
    func presentListingPreview(
        item: ListingFeedItem,
        router: AppRouter,
        publicBrowse: Bool,
        surface: String = "explore",
        position: Int = 0
    ) {
        feedEventReporter.previewOpen(listingId: item.id, surface: surface, position: position)
        feedEventReporter.impression(listingId: item.id, surface: surface, position: position)
        Task { _ = await listingRepository.recordView(listingId: item.id) }
        listingPreview.open(
            item: item,
            deps: self,
            publicBrowse: publicBrowse,
            surface: surface,
            position: position
        )
    }

    /// Opens full product detail; preview dismisses in parallel (no wait for sheet).
    /// When `dismissExploreOverlay` is nil, Explore stays open if it is already showing (back returns to Khám phá).
    func presentListingDetail(
        listingId: String,
        router: AppRouter,
        dismissExploreOverlay: Bool? = nil
    ) {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        let shouldDismissExplore = dismissExploreOverlay ?? !router.showExploreOverlay
        dismissExploreOverlayIfNeeded(router, when: shouldDismissExplore)
        router.pendingListingIdAfterPreview = nil
        router.openListingDetailFlow(rootId: id)
        listingPreview.close(deps: self, animated: true)
    }

    /// Navigate to seller shop while preview animates away underneath the new screen.
    func navigateFromListingPreview(
        router: AppRouter,
        dismissExploreOverlay: Bool? = nil,
        _ navigate: () -> Void
    ) {
        let shouldDismissExplore = dismissExploreOverlay ?? !router.showExploreOverlay
        dismissExploreOverlayIfNeeded(router, when: shouldDismissExplore)
        router.pendingListingIdAfterPreview = nil
        navigate()
        listingPreview.close(deps: self, animated: true)
    }

    /// Opens seller storefront above main chrome — closes PDP/preview and Explore overlay so RootView `fullScreenRoute` `.seller` is visible.
    func openSellerShop(username: String, router: AppRouter, dismissExploreOverlay: Bool = true) {
        let handle = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        guard !handle.isEmpty else { return }
        router.closeListingDetailFlow()
        router.pendingListingIdAfterPreview = nil
        listingPreview.close(deps: self, animated: true)
        dismissExploreOverlayIfNeeded(router, when: dismissExploreOverlay)
        router.sellerShopUsername = handle
    }

    private func dismissExploreOverlayIfNeeded(_ router: AppRouter, when shouldDismiss: Bool) {
        guard shouldDismiss, router.showExploreOverlay else { return }
        router.showExploreOverlay = false
        router.exploreSearchExpanded = false
    }
}
