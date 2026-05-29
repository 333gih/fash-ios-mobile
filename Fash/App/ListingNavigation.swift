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
    func presentListingDetail(listingId: String, router: AppRouter) {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        dismissExploreOverlayIfNeeded(router)
        router.pendingListingIdAfterPreview = nil
        router.selectedListingId = id
        listingPreview.close(deps: self, animated: true)
    }

    /// Navigate to seller shop while preview animates away underneath the new screen.
    func navigateFromListingPreview(router: AppRouter, _ navigate: () -> Void) {
        dismissExploreOverlayIfNeeded(router)
        router.pendingListingIdAfterPreview = nil
        navigate()
        listingPreview.close(deps: self, animated: true)
    }

    private func dismissExploreOverlayIfNeeded(_ router: AppRouter) {
        guard router.showExploreOverlay else { return }
        router.showExploreOverlay = false
        router.exploreSearchExpanded = false
    }
}
