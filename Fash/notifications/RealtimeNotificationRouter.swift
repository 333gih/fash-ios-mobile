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
            let pushData = data ?? [:]
            if AccountSwitchDeepLinks.parseFromFcmData(pushData) != nil {
                return
            }
            if AppPromoPushParsing.isAppPromoPushData(pushData),
               let campaign = AppPromoPushParsing.parseAppPromoFromPushData(
                   data: pushData,
                   fallbackTitle: title,
                   fallbackBody: body
               ) {
                deps.requestShowAppPromo(campaign)
                deps.requestInboxUnreadRefresh()
                return
            }
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            let openId = ChatNotificationPresence.openConversationId(deps: deps)
            if ChatInAppNotificationPolicy.shouldSuppressInApp(data: pushData, openConversationId: openId) {
                ChatNotificationPresence.handleSuppressedChatNotification(data: pushData, deps: deps)
                if ChatInAppNotificationPolicy.isChatRelated(data: pushData) {
                    refreshChatInbox(chatVM: chatVM, deps: deps)
                }
                return
            }
            deps.showInAppNotification(
                FashInAppNotificationSession(
                    title: title,
                    body: body,
                    userNotificationId: userNotificationId,
                    dataMap: pushData
                ),
                chatVM: chatVM
            )
            deps.requestInboxUnreadRefresh()
            if isChatPushData(pushData) {
                refreshChatInbox(chatVM: chatVM, deps: deps)
            }
        case .appPromoShow(let campaignJson):
            if let campaign = AppPromoPushParsing.parseRealtimeCampaignJson(campaignJson) {
                deps.requestShowAppPromo(campaign)
                deps.requestInboxUnreadRefresh()
            }
        case .feedRefresh:
            Task {
                await homeVM.handleFeedRefresh(deps: deps, isGuestMode: isGuestMode)
                await exploreVM.handleFeedRefresh(deps: deps, isGuestMode: isGuestMode)
            }
        case .messageNew(
            let conversationId,
            _,
            let senderId,
            let recipientId,
            let preview,
            let messageType,
            let systemSubtype
        ):
            refreshChatInbox(chatVM: chatVM, deps: deps)
            guard !isGuestMode else { return }
            let myId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let openId = ChatNotificationPresence.openConversationId(deps: deps)
            let cid = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
            if ChatInAppNotificationPolicy.isOpenConversation(cid, openConversationId: openId) {
                ChatNotificationPresence.handleSuppressedChatNotification(
                    data: ["conversation_id": cid],
                    deps: deps
                )
                return
            }
            guard ChatInAppNotificationPolicy.shouldShowMessageNewInApp(
                conversationId: conversationId,
                senderId: senderId,
                recipientId: recipientId,
                messageType: messageType,
                systemSubtype: systemSubtype,
                myUserId: myId,
                openConversationId: openId
            ) else { return }
            let trimmedPreview = preview.trimmingCharacters(in: .whitespacesAndNewlines)
            var dataMap: [String: String] = [:]
            if !cid.isEmpty { dataMap["conversation_id"] = cid }
            let bannerTitle = InAppNotificationPresentation.chatMessageNewTitle(
                conversationId: cid,
                senderId: senderId,
                chatVM: chatVM
            )
            deps.showInAppNotification(
                FashInAppNotificationSession(
                    title: bannerTitle,
                    body: trimmedPreview.isEmpty ? L10n.notificationPtMarketplaceChatMessage : trimmedPreview,
                    userNotificationId: nil,
                    dataMap: dataMap
                ),
                chatVM: chatVM
            )
        case .readReceipts, .conversationClosed, .conversationReopened:
            refreshChatInbox(chatVM: chatVM, deps: deps)
        case .offerLimitReset, .listingReserved, .listingAvailable, .listingSold:
            refreshChatInbox(chatVM: chatVM, deps: deps)
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
        NotificationEngagementReporter.reportOpen(reporter: deps.feedEventReporter, data: session.dataMap)
        deps.dismissInAppNotification()
        let data = session.dataMap

        // Chat/deal threads first — inbox row also has user_notification_id but user expects the thread.
        if let convId = InAppNotificationNavigation.chatConversationId(from: data) {
            InAppNotificationNavigation.openChat(conversationId: convId, router: router, deps: deps)
            return
        }

        if let deepLink = data["deep_link"]?.trimmingCharacters(in: .whitespaces), !deepLink.isEmpty,
           let url = URL(string: deepLink) {
            DeepLinkRouter.handle(url: url, router: router, deps: deps)
            return
        }

        let nav = data["nav_target"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            ?? data["navTarget"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            ?? ""
        if nav == "in_app_invite_friends" {
            router.showInviteFriendsScreen = true
            return
        }
        if nav == "order", let orderId = InAppNotificationNavigation.orderId(from: data) {
            InAppNotificationNavigation.openOrder(orderId: orderId, router: router, deps: deps)
            return
        }

        if let inboxId = session.userNotificationId?.trimmingCharacters(in: .whitespaces), !inboxId.isEmpty {
            router.showNotificationScreen = true
            router.notificationDetailId = inboxId
            return
        }
        if let inboxId = data["user_notification_id"]?.trimmingCharacters(in: .whitespaces), !inboxId.isEmpty {
            router.showNotificationScreen = true
            router.notificationDetailId = inboxId
            return
        }

        router.showNotificationScreen = true
    }

    private static func refreshChatInbox(chatVM: ChatViewModel, deps: AppDependencies) {
        Task {
            await chatVM.silentRefresh(deps: deps)
            await chatVM.refreshUnreadCount(deps: deps)
        }
    }

    private static func isChatPushData(_ data: [String: String]?) -> Bool {
        guard let type = data?["type"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !type.isEmpty else { return false }
        return type.contains("chat")
            || type.contains("message")
            || type == "marketplace.chat.message"
            || type == "marketplace.chat.offer_received"
            || type == "marketplace.chat.offer_accepted"
            || type == "marketplace.chat.offer_declined"
    }
}
