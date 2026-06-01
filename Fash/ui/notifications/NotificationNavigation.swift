import Foundation

/// Parsed from inbox `data` / FCM data map for primary actions on the detail screen.
struct NotificationDetailActions: Equatable {
    let orderId: String?
    let listingId: String?
    let sellerUserId: String?
    let conversationId: String?
    let openFollowersTab: Bool
    let openFollowingTab: Bool
    let openExploreTab: Bool
    let openInviteFriends: Bool
    let richDetailBody: String?
    let imageUrl: String?
}

enum NotificationNavigation {
    static func parseNotificationDetailActions(_ item: InboxNotificationItem) -> NotificationDetailActions {
        if let promo = NotificationPromoDetail.parseAppPromoCampaignFromInbox(item) {
            let rich = promo.remoteMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
            let richBody = (rich?.isEmpty == false && rich != item.body) ? rich : nil
            return NotificationDetailActions(
                orderId: nil,
                listingId: nil,
                sellerUserId: nil,
                conversationId: nil,
                openFollowersTab: false,
                openFollowingTab: false,
                openExploreTab: false,
                openInviteFriends: false,
                richDetailBody: richBody,
                imageUrl: promo.remoteImageUrls.first
            )
        }

        let data = item.dataMap
        let orderId = firstStringFromDataCi(data, "order_id", "marketplace_order_id", "orderId")
        let listingId = firstStringFromDataCi(data, "listing_id", "listingId")
        let sellerUserId = sellerUserIdFromData(data)
        let conversationId = firstStringFromDataCi(data, "conversation_id", "conversationId")
        let nav = firstStringFromDataCi(data, "nav_target", "navTarget")?.lowercased() ?? ""
        let screen = firstStringFromDataCi(data, "screen")?.lowercased() ?? ""
        let ptype = item.payloadType?.lowercased() ?? ""

        let openFollowersTab = nav == "followers_tab"
            || ptype == "marketplace.follower.new"
            || ptype == "marketplace.follower.batch"

        let openFollowingTab = nav == "following_tab"
        let openExploreTab = nav == "explore_tab" || nav == "explore"
        let openInviteFriends = nav == "in_app_invite_friends"
            || ptype == "marketplace.referral.invite_rewarded"

        let rich = firstStringFromDataCi(data, "detail_body", "detailBody", "rich_body", "richBody")
        let imageUrl = firstStringFromDataCi(
            data,
            "notification_image_url",
            "notificationImageUrl",
            "image_url",
            "imageUrl"
        )

        let wantsChat = nav == "chat" || screen == "chat"
        let chatId: String? = {
            guard wantsChat, let id = conversationId, !id.isEmpty else { return nil }
            return id
        }()

        return NotificationDetailActions(
            orderId: orderId,
            listingId: listingId,
            sellerUserId: sellerUserId,
            conversationId: chatId,
            openFollowersTab: openFollowersTab,
            openFollowingTab: openFollowingTab,
            openExploreTab: openExploreTab,
            openInviteFriends: openInviteFriends,
            richDetailBody: rich,
            imageUrl: imageUrl
        )
    }

    static func firstStringFromDataCi(_ data: [String: Any]?, _ keys: String...) -> String? {
        guard let data else { return nil }
        let byLower = Dictionary(uniqueKeysWithValues: data.map { ($0.key.lowercased(), $0.value) })
        for key in keys {
            guard let value = byLower[key.lowercased()] else { continue }
            let trimmed: String
            switch value {
            case let s as String:
                trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            case let n as NSNumber:
                trimmed = n.stringValue
            default:
                trimmed = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    static func sellerUserIdFromData(_ data: [String: Any]?) -> String? {
        firstStringFromDataCi(data, "seller_user_id", "sellerUserId", "seller_id", "sellerId")
    }
}
