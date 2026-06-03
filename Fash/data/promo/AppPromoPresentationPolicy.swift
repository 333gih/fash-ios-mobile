import Foundation

/// Routes admin app-promo realtime/FCM: dialog vs in-app vs suppressed duplicate toast.
@MainActor
enum AppPromoPresentationPolicy {
    static func isInChatDetail(openConversationId: String?) -> Bool {
        let id = openConversationId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !id.isEmpty
    }

    /// After the blocking dialog was shown (any dismiss/CTA), skip redundant in-app toasts.
    static func shouldSuppressInAppToast(for campaign: AppPromoCampaign) -> Bool {
        AppPromoCampaignStore.isDismissed(campaign)
            || AppPromoCampaignStore.hasRecordedShow(campaign)
    }

    static func promoInAppDataMap(
        campaign: AppPromoCampaign,
        userNotificationId: String?
    ) -> [String: String] {
        var data: [String: String] = [
            "type": AppPromoPushParsing.adminAppPromoPayloadType,
            "campaign_id": campaign.campaignId,
            "campaign_version": String(campaign.version),
        ]
        if let nid = userNotificationId?.trimmingCharacters(in: .whitespacesAndNewlines), !nid.isEmpty {
            data["user_notification_id"] = nid
        }
        return data
    }

    static func handleIncoming(
        campaign: AppPromoCampaign,
        deps: AppDependencies,
        openConversationId: String?,
        userNotificationId: String?,
        chatVM: ChatViewModel?
    ) {
        AppPromoPendingQueue.enqueue(campaign)
        deps.requestInboxUnreadRefresh()

        if isInChatDetail(openConversationId: openConversationId) {
            guard !shouldSuppressInAppToast(for: campaign) else { return }
            let title = RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteTitle) ?? ""
            let body = RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteMessage) ?? ""
            guard !title.isEmpty || !body.isEmpty else { return }
            deps.showInAppNotification(
                FashInAppNotificationSession(
                    title: title,
                    body: body,
                    userNotificationId: userNotificationId,
                    dataMap: promoInAppDataMap(campaign: campaign, userNotificationId: userNotificationId)
                ),
                chatVM: chatVM
            )
            return
        }

        deps.requestShowAppPromo(campaign)
    }

    static func markInboxReadAfterDialogShown(
        campaign: AppPromoCampaign,
        userRepository: UserRepository
    ) {
        Task {
            await InboxNotificationSync.markAppPromoNotificationsRead(
                campaignId: campaign.campaignId,
                version: campaign.version,
                userRepository: userRepository
            )
            await MainActor.run {
                AppDependencies.shared.requestInboxUnreadRefresh()
            }
        }
    }
}
