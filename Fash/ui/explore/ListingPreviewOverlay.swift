import SwiftUI

/// In-tab listing quick-look overlay (lower z-order than RootView full-screen routes).
struct ListingPreviewOverlay: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var listingPreview: ListingPreviewStore
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var onRequestLogin: (() -> Void)?
    var onFeedEngagementPatch: ((String, (ListingFeedItem) -> ListingFeedItem) -> Void)? = nil

    @State private var isOpeningChat = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if listingPreview.isOverlayVisible {
                Color.black.opacity(0.38)
                    .ignoresSafeArea()
                    .onTapGesture { listingPreview.close(deps: deps, animated: true) }
                    .transition(.opacity)

                if let preview = listingPreview.state {
                    let sheetHeight = max(screenHeight / 3, 240)
                    let listingId = preview.feedItem.id
                    let hasExisting = deps.conversationIdForListing(listingId) != nil
                    ExploreListingPreviewSheet(
                        feedItem: preview.feedItem,
                        detail: preview.detail,
                        isDetailLoading: preview.isDetailLoading,
                        isGuestMode: isGuestMode,
                        hasExistingConversation: hasExisting,
                        onViewDetail: {
                            listingPreview.openDetail(deps: deps)
                            deps.presentListingDetail(listingId: listingId, router: router)
                        },
                        onLike: { Task { await toggleLike(preview) } },
                        onSave: { Task { await toggleSave(preview) } },
                        onMessageSeller: {
                            Task { await openChat(listingId: listingId) }
                        },
                        onOpenSeller: {
                            let username = previewSellerUsername(preview)
                            guard !username.isEmpty else { return }
                            deps.openSellerShop(username: username, router: router)
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
                    .padding(.bottom, 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .disabled(isOpeningChat)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut(duration: 0.28), value: listingPreview.isOverlayVisible)
        .allowsHitTesting(listingPreview.isOverlayVisible)
    }

    private var screenHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.height }
            .first ?? 800
    }

    private func openChat(listingId: String) async {
        guard !isOpeningChat else { return }
        isOpeningChat = true
        defer { isOpeningChat = false }
        if let existing = deps.conversationIdForListing(listingId) {
            listingPreview.close(deps: deps, animated: true)
            router.selectedConversationId = existing
            return
        }
        switch await deps.chatRepository.startConversation(listingId: listingId) {
        case .success(let convId):
            listingPreview.close(deps: deps, animated: true)
            deps.rememberChatListingConversation(listingId: listingId, conversationId: convId)
            deps.chatInboxRefreshGeneration &+= 1
            router.selectedConversationId = convId
        case .failure(let error):
            deps.showSnackbar(FashErrorPresentation.userMessage(for: error))
        }
    }

    private func previewSellerUsername(_ preview: ExploreListingPreviewState) -> String {
        let fromDetail = preview.detail?.sellerUsername?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromDetail.isEmpty { return fromDetail }
        let fromFeed = preview.feedItem.sellerUsername?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromFeed.isEmpty { return fromFeed }
        return preview.feedItem.sellerId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func toggleLike(_ preview: ExploreListingPreviewState) async {
        guard !isGuestMode else { onRequestLogin?(); return }
        let snapshot = preview.feedItem
        guard deps.listingEngagement.beginLikeToggle(listingId: snapshot.id) else { return }
        applyEngagementPatch(listingId: snapshot.id) { _ in snapshot.toggledLike }
        defer { deps.listingEngagement.endLikeToggle(listingId: snapshot.id) }
        switch await deps.listingRepository.toggleLike(listingId: snapshot.id) {
        case .failure(let error):
            applyEngagementPatch(listingId: snapshot.id) { _ in snapshot }
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        case .success(let liked):
            applyEngagementPatch(listingId: snapshot.id) { _ in snapshot.applyingLikeToggle(liked) }
            deps.showSnackbar(FeedEngagementFeedback.likeMessage(liked: liked))
        }
    }

    private func toggleSave(_ preview: ExploreListingPreviewState) async {
        guard !isGuestMode else { onRequestLogin?(); return }
        let snapshot = preview.feedItem
        guard deps.listingEngagement.beginSaveToggle(listingId: snapshot.id) else { return }
        applyEngagementPatch(listingId: snapshot.id) { _ in snapshot.toggledSave }
        defer { deps.listingEngagement.endSaveToggle(listingId: snapshot.id) }
        switch await deps.listingRepository.toggleSave(
            listingId: snapshot.id,
            currentlySaved: snapshot.isSaved
        ) {
        case .failure(let error):
            applyEngagementPatch(listingId: snapshot.id) { _ in snapshot }
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        case .success(let saved):
            applyEngagementPatch(listingId: snapshot.id) { _ in snapshot.applyingSaveToggle(saved) }
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
