import Foundation

extension AppDependencies {
    /// Opens listing quick-look; dismisses Explore overlay first so the sheet can present safely.
    func presentListingPreview(
        item: ListingFeedItem,
        router: AppRouter,
        publicBrowse: Bool,
        surface: String = "explore",
        position: Int = 0
    ) {
        dismissExploreOverlayIfNeeded(router)
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

    /// Opens full product detail; clears preview and Explore overlay to avoid nested covers.
    func presentListingDetail(listingId: String, router: AppRouter) {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        dismissExploreOverlayIfNeeded(router)
        listingPreview.close(deps: self)
        router.pendingListingIdAfterPreview = nil
        router.selectedListingId = id
    }

    private func dismissExploreOverlayIfNeeded(_ router: AppRouter) {
        guard router.showExploreOverlay else { return }
        router.showExploreOverlay = false
        router.exploreSearchExpanded = false
    }
}
