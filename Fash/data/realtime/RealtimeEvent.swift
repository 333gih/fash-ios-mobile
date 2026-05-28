import Foundation

/// Events emitted by [RealtimeManager] — Android `RealtimeEvent.kt`.
enum RealtimeEvent: Equatable {
    case connected(userId: String, connId: String)
    case disconnected(willReconnect: Bool)
    case messageNew(
        conversationId: String,
        messageId: String,
        senderId: String,
        recipientId: String,
        preview: String,
        messageType: String,
        systemSubtype: String?
    )
    case readReceipts(conversationId: String, readerId: String, notifyUserId: String)
    case typingStart(conversationId: String, userId: String)
    case typingStop(conversationId: String, userId: String)
    case orderStatusChanged(orderId: String, conversationId: String, newStatus: String)
    case offerLimitReset(listingId: String, conversationId: String, newPriceVnd: Int64)
    case listingReserved(listingId: String)
    case listingAvailable(listingId: String)
    case listingSold(listingId: String)
    case conversationClosed(conversationId: String)
    case conversationReopened(conversationId: String)
    case feedRefresh
    case inboxRefresh
    case notificationShow(title: String, body: String, data: [String: String]?, userNotificationId: String?)
    case appPromoShow(campaignJson: String)
    case pong
    case unknown(type: String)

    static func parse(jsonText: String) -> RealtimeEvent? {
        guard let data = jsonText.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let type = (root["type"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        let payload = root["payload"] as? [String: Any] ?? [:]

        func field(_ keys: String...) -> String {
            for key in keys {
                if let s = payload[key] as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty {
                    return s.trimmingCharacters(in: .whitespaces)
                }
                if let s = root[key] as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty {
                    return s.trimmingCharacters(in: .whitespaces)
                }
            }
            return ""
        }

        switch type {
        case "connected":
            return .connected(userId: field("user_id", "UserID", "userId"), connId: field("conn_id", "ConnID", "connId"))
        case "message.new":
            let sys = field("system_subtype", "system_type", "SystemSubtype", "subtype", "SubType")
            let msgTypeRaw = field("message_type", "MessageType")
            return .messageNew(
                conversationId: field("conversation_id", "ConversationID", "conversationId"),
                messageId: field("message_id", "MessageID", "messageId", "ID", "Id"),
                senderId: field("sender_id", "SenderID", "senderId"),
                recipientId: field("recipient_id", "RecipientID", "recipientId"),
                preview: field("preview", "Preview"),
                messageType: msgTypeRaw.isEmpty ? "text" : msgTypeRaw,
                systemSubtype: sys.isEmpty ? nil : sys
            )
        case "read.receipts", "read.ack":
            return .readReceipts(
                conversationId: field("conversation_id", "ConversationID", "conversationId"),
                readerId: field("read_by", "ReadBy", "recipient_id", "RecipientID", "reader_id", "ReaderID"),
                notifyUserId: field("notify_user_id", "NotifyUserID")
            )
        case "typing.start":
            return .typingStart(
                conversationId: field("conversation_id", "ConversationID", "conversationId"),
                userId: field("user_id", "UserID", "sender_id", "SenderID")
            )
        case "typing.stop":
            return .typingStop(
                conversationId: field("conversation_id", "ConversationID", "conversationId"),
                userId: field("user_id", "UserID", "sender_id", "SenderID")
            )
        case "order.status_changed":
            return .orderStatusChanged(
                orderId: field("order_id", "OrderID", "orderId"),
                conversationId: field("conversation_id", "ConversationID", "conversationId"),
                newStatus: field("new_status", "NewStatus", "status", "Status")
            )
        case "offer.limit_reset":
            let price = (payload["new_price_vnd"] as? NSNumber)?.int64Value
                ?? (root["new_price_vnd"] as? NSNumber)?.int64Value ?? 0
            return .offerLimitReset(
                listingId: field("listing_id", "ListingID", "listingId"),
                conversationId: field("conversation_id", "ConversationID", "conversationId"),
                newPriceVnd: price
            )
        case "listing.reserved":
            return .listingReserved(listingId: field("listing_id", "ListingID", "listingId"))
        case "listing.available":
            return .listingAvailable(listingId: field("listing_id", "ListingID", "listingId"))
        case "listing.sold":
            return .listingSold(listingId: field("listing_id", "ListingID", "listingId"))
        case "conversation.closed":
            return .conversationClosed(conversationId: field("conversation_id", "ConversationID", "conversationId"))
        case "conversation.reopened":
            return .conversationReopened(conversationId: field("conversation_id", "ConversationID", "conversationId"))
        case "feed.refresh":
            return .feedRefresh
        case "inbox.refresh":
            return .inboxRefresh
        case "notification.show":
            let title = field("title", "Title")
            let body = field("body", "Body")
            let dataObj = payload["data"] as? [String: Any] ?? root["data"] as? [String: Any]
            var dataMap: [String: String]?
            if let dataObj {
                var map: [String: String] = [:]
                for (key, value) in dataObj {
                    if let s = value as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty {
                        map[key] = s.trimmingCharacters(in: .whitespaces)
                    } else if let n = value as? NSNumber {
                        map[key] = n.stringValue
                    }
                }
                dataMap = map.isEmpty ? nil : map
            }
            let nid = field("user_notification_id", "userNotificationId", "UserNotificationID")
            return .notificationShow(
                title: title,
                body: body,
                data: dataMap,
                userNotificationId: nid.isEmpty ? nil : nid
            )
        case "app.promo.show":
            let campaign = payload["campaign"] as? [String: Any] ?? root["campaign"] as? [String: Any] ?? [:]
            let json = (try? JSONSerialization.data(withJSONObject: campaign)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            return .appPromoShow(campaignJson: json)
        case "pong":
            return .pong
        default:
            return type.isEmpty ? nil : .unknown(type: type)
        }
    }
}
