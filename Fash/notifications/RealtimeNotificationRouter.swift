import Foundation

/// Routes global realtime + push notification signals — Android MainActivity collectors.
@MainActor
enum RealtimeNotificationRouter {
    static func handle(
        _ event: RealtimeEvent,
        deps: AppDependencies,
        router: AppRouter,
        notificationsVM: NotificationsViewModel,
        chatVM: ChatViewModel,
        homeVM: HomeViewModel,
        exploreVM: ExploreViewModel,
        isGuestMode: Bool
    ) {
        switch event {
        case .inboxRefresh:
            deps.requestInboxUnreadRefresh()
        case .notificationShow(let title, let body, let data, let userNotificationId):
            if AppPromoPushParsing.isAppPromoPushData(data),
               let campaign = AppPromoPushParsing.parseAppPromoFromPushData(
                   data: data ?? [:],
                   fallbackTitle: title,
                   fallbackBody: body
               ) {
                deps.uiDialog.title = campaign.title
                deps.uiDialog.message = campaign.body
                deps.uiDialog.isPresented = true
                deps.requestInboxUnreadRefresh()
                return
            }
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            deps.showInAppNotification(FashInAppNotificationSession(
                title: title,
                body: body,
                userNotificationId: userNotificationId,
                dataMap: data ?? [:]
            ))
            deps.requestInboxUnreadRefresh()
            if isChatPushData(data) {
                Task { await chatVM.silentRefresh(deps: deps) }
            }
        case .appPromoShow(let campaignJson):
            if let campaign = AppPromoPushParsing.parseRealtimeCampaignJson(campaignJson) {
                deps.uiDialog.title = campaign.title
                deps.uiDialog.message = campaign.body
                deps.uiDialog.isPresented = true
                deps.requestInboxUnreadRefresh()
            }
        case .feedRefresh:
            Task {
                await homeVM.handleFeedRefresh(deps: deps, isGuestMode: isGuestMode)
                await exploreVM.handleFeedRefresh(deps: deps, isGuestMode: isGuestMode)
            }
        case .messageNew, .readReceipts, .conversationClosed, .conversationReopened:
            Task { await chatVM.silentRefresh(deps: deps) }
        case .connected:
            Task {
                await chatVM.resyncConversationSubscriptions(deps: deps)
                await notificationsVM.refreshUnreadSummary()
            }
        case .orderStatusChanged:
            break
        default:
            break
        }
    }

    static func handleInAppBannerTap(
        session: FashInAppNotificationSession,
        deps: AppDependencies,
        router: AppRouter
    ) {
        deps.inAppNotification = nil
        let data = session.dataMap

        if let inboxId = session.userNotificationId?.trimmingCharacters(in: .whitespaces), !inboxId.isEmpty {
            router.showNotificationScreen = true
            router.notificationDetailId = inboxId
            return
        }
        if let deepLink = data["deep_link"]?.trimmingCharacters(in: .whitespaces), !deepLink.isEmpty,
           let url = URL(string: deepLink) {
            DeepLinkRouter.handle(url: url, router: router, deps: deps)
            return
        }
        if data["nav_target"] == "in_app_invite_friends" {
            router.showInviteFriendsScreen = true
            return
        }
        if let convId = data["conversation_id"]?.trimmingCharacters(in: .whitespaces), !convId.isEmpty {
            router.selectedTab = .chat
            router.selectedConversationId = convId
            return
        }
        router.showNotificationScreen = true
    }

    private static func isChatPushData(_ data: [String: String]?) -> Bool {
        guard let type = data?["type"]?.lowercased() else { return false }
        return type.contains("chat") || type.contains("message")
    }
}
