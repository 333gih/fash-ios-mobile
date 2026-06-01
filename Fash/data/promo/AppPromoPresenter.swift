import Foundation

@MainActor
enum AppPromoPresenter {
    static func presentAdminPromoIfEligible(
        _ promo: AppPromoCampaign,
        active: inout AppPromoCampaign?,
        isGuestMode: Bool,
        selectedConversationId: String?
    ) {
        AppPromoPendingQueue.enqueue(promo)
        guard !isGuestMode, selectedConversationId == nil else { return }
        guard AppPromoCampaignStore.canShow(promo) else { return }
        active = promo
        AppPromoCampaignStore.recordShow(promo)
    }

    static func pollQueuedPromoIfEligible(
        active: inout AppPromoCampaign?,
        isGuestMode: Bool,
        selectedConversationId: String?
    ) {
        guard !isGuestMode, selectedConversationId == nil, active == nil else { return }
        guard let remote = AppPromoPendingQueue.peekHighest(),
              AppPromoCampaignStore.canShow(remote) else { return }
        active = remote
        AppPromoCampaignStore.recordShow(remote)
    }
}
