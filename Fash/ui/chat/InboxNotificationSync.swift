import Foundation

/// Keeps notification inbox unread in sync when a chat thread is read in-app.
enum InboxNotificationSync {
    private static let chatGroups = ["REALTIME", "REENGAGEMENT"]
    private static let promoGroups = ["ADS", "SYSTEM", "GENERAL"]

    static func markAppPromoNotificationsRead(
        campaignId: String,
        version: Int,
        userNotificationId: String? = nil,
        userRepository: UserRepository
    ) async {
        let cid = campaignId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return }

        if let nid = userNotificationId?.trimmingCharacters(in: .whitespacesAndNewlines), !nid.isEmpty {
            _ = await userRepository.markNotificationRead(notificationId: nid)
        }

        for group in promoGroups {
            guard case .success(let page) = await userRepository.listMyNotifications(limit: 100, group: group) else {
                continue
            }
            await markPromoUnreadItems(
                items: page.items,
                campaignId: cid,
                version: version,
                userRepository: userRepository
            )
        }
        if case .success(let page) = await userRepository.listMyNotifications(limit: 100, group: nil) {
            await markPromoUnreadItems(
                items: page.items,
                campaignId: cid,
                version: version,
                userRepository: userRepository
            )
        }
    }

    private static func markPromoUnreadItems(
        items: [InboxNotificationItem],
        campaignId: String,
        version: Int,
        userRepository: UserRepository
    ) async {
        for item in items where item.isUnread {
            guard NotificationPromoDetail.isAppPromoInboxNotification(item) else { continue }
            if NotificationPromoDetail.matchesCampaign(
                item: item,
                campaignId: campaignId,
                version: version
            ) {
                _ = await userRepository.markNotificationRead(notificationId: item.id)
            }
        }
    }

    static func markChatNotificationsRead(
        forConversationId conversationId: String,
        userRepository: UserRepository
    ) async {
        let cid = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return }

        for group in chatGroups {
            guard case .success(let page) = await userRepository.listMyNotifications(limit: 100, group: group) else {
                continue
            }
            for item in page.items where item.isUnread {
                guard let itemConv = parseConversationId(from: item.dataMap) else { continue }
                guard itemConv.compare(cid, options: .caseInsensitive) == .orderedSame else { continue }
                _ = await userRepository.markNotificationRead(notificationId: item.id)
            }
        }
    }

    private static func parseConversationId(from data: [String: Any]?) -> String? {
        guard let data else { return nil }
        for key in ["conversation_id", "conversationId", "ConversationID"] {
            let raw = data[key]
            let value: String
            if let s = raw as? String {
                value = s
            } else if let n = raw {
                value = String(describing: n)
            } else {
                continue
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}
