import SwiftUI

/// In-tab listing quick-look overlay (lower z-order than RootView full-screen routes).
struct ListingPreviewOverlay: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var listingPreview: ListingPreviewStore
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var onRequestLogin: (() -> Void)?
    var onFeedEngagementPatch: ((String, (ListingFeedItem) -> ListingFeedItem) -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            if listingPreview.isOverlayVisible {
                Color.black.opacity(0.38)
                    .ignoresSafeArea()
                    .onTapGesture { listingPreview.close(deps: deps, animated: true) }
                    .transition(.opacity)

                if let preview = listingPreview.state {
                    let sheetHeight = max(screenHeight / 3, 240)
                    ExploreListingPreviewSheet(
                        feedItem: preview.feedItem,
                        detail: preview.detail,
                        isDetailLoading: preview.isDetailLoading,
                        isGuestMode: isGuestMode,
                        onViewDetail: {
                            listingPreview.openDetail(deps: deps)
                            deps.presentListingDetail(listingId: preview.feedItem.id, router: router)
                        },
                        onLike: { Task { await toggleLike(preview) } },
                        onSave: { Task { await toggleSave(preview) } },
                        onMessageSeller: {
                            listingPreview.openDetail(deps: deps)
                            deps.presentListingDetail(listingId: preview.feedItem.id, router: router)
                        },
                        onOpenSeller: {
                            let username = previewSellerUsername(preview)
                            guard !username.isEmpty else { return }
                            deps.navigateFromListingPreview(router: router) {
                                router.sellerShopUsername = username
                            }
                        },
                        onRequestLogin: onRequestLogin
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: sheetHeight, alignment: .top)
                    .background(FashColors.screen)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 16,
                            topTrailingRadius: 16
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, y: -4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: listingPreview.isOverlayVisible)
        .allowsHitTesting(listingPreview.isOverlayVisible)
    }

    private var screenHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.height }
            .first ?? 800
    }

    private func previewSellerUsername(_ preview: ExploreListingPreviewState) -> String {
        let fromDetail = preview.detail?.sellerUsername?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromDetail.isEmpty { return fromDetail }
        return preview.feedItem.sellerUsername?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func toggleLike(_ preview: ExploreListingPreviewState) async {
        guard !isGuestMode else { onRequestLogin?(); return }
        switch await deps.listingRepository.toggleLike(listingId: preview.feedItem.id) {
        case .failure(let error):
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        case .success(let liked):
            applyEngagementPatch(listingId: preview.feedItem.id) { $0.applyingLikeToggle(liked) }
            deps.showSnackbar(FeedEngagementFeedback.likeMessage(liked: liked))
        }
    }

    private func toggleSave(_ preview: ExploreListingPreviewState) async {
        guard !isGuestMode else { onRequestLogin?(); return }
        switch await deps.listingRepository.toggleSave(
            listingId: preview.feedItem.id,
            currentlySaved: preview.feedItem.isSaved
        ) {
        case .failure(let error):
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        case .success(let saved):
            applyEngagementPatch(listingId: preview.feedItem.id) { $0.applyingSaveToggle(saved) }
            deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
        }
    }

    private func applyEngagementPatch(
        listingId: String,
        transform: (ListingFeedItem) -> ListingFeedItem
    ) {
        listingPreview.patchFeedItem(listingId, transform: transform)
        onFeedEngagementPatch?(listingId, transform)
    }
}
