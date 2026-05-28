import SwiftUI

/// Presents listing quick-look at ~⅓ screen height — Android `ExploreListingPreviewSheet`.
struct ListingPreviewSheetHost: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var listingPreview: ListingPreviewStore
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var onRequestLogin: (() -> Void)?

    var body: some View {
        GeometryReader { geo in
            let sheetHeight = max(geo.size.height / 3, 240)
            if let preview = listingPreview.state {
                ExploreListingPreviewSheet(
                    feedItem: preview.feedItem,
                    detail: preview.detail,
                    isDetailLoading: preview.isDetailLoading,
                    isGuestMode: isGuestMode,
                    onViewDetail: {
                        listingPreview.openDetail(deps: deps)
                        router.pendingListingIdAfterPreview = preview.feedItem.id
                        listingPreview.close(deps: deps)
                    },
                    onLike: { Task { await toggleLike(preview) } },
                    onSave: { Task { await toggleSave(preview) } },
                    onMessageSeller: {
                        listingPreview.openDetail(deps: deps)
                        router.pendingListingIdAfterPreview = preview.feedItem.id
                        listingPreview.close(deps: deps)
                    },
                    onRequestLogin: onRequestLogin
                )
                .frame(width: geo.size.width, height: sheetHeight, alignment: .top)
                .clipped()
            }
        }
        .presentationDetents([.fraction(1.0 / 3.0)])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(1.0 / 3.0)))
        .environment(\.locale, AppLocale.locale)
    }

    private func toggleLike(_ preview: ExploreListingPreviewState) async {
        guard !isGuestMode else { onRequestLogin?(); return }
        _ = await deps.listingRepository.toggleLike(listingId: preview.feedItem.id)
    }

    private func toggleSave(_ preview: ExploreListingPreviewState) async {
        guard !isGuestMode else { onRequestLogin?(); return }
        _ = await deps.listingRepository.toggleSave(
            listingId: preview.feedItem.id,
            currentlySaved: preview.feedItem.isSaved
        )
    }
}
