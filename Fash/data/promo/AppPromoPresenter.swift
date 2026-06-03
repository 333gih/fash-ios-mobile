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
        guard !AppPromoCampaignStore.isDialogConsumed(promo) else {
            AppPromoPendingQueue.remove(campaignId: promo.campaignId)
            return
        }
        guard AppPromoCampaignStore.canShow(promo) else { return }
        active = promo
        AppPromoCampaignStore.recordShow(promo)
        AppPromoCampaignStore.markDialogConsumed(promo)
        AppPromoPendingQueue.remove(campaignId: promo.campaignId)
        AppPromoPresentationPolicy.markInboxReadAfterDialogShown(
            campaign: promo,
            userRepository: AppDependencies.shared.userRepository
        )
    }
}
