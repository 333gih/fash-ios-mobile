import Foundation

/// Chat/conversations API — Android [ChatRepository] (inbox list).
final class ChatRepository {
    private let client: SecuredApiClient
    private let sessionStore: AuthSessionStore

    init(client: SecuredApiClient, sessionStore: AuthSessionStore) {
        self.client = client
        self.sessionStore = sessionStore
    }

    func getConversations(limit: Int = 50, offset: Int = 0) async -> Result<[ConversationItem], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/chat/conversations?limit=\(limit)&offset=\(offset)",
                client: client
            )
            return .success(parseConversations(data))
        } catch {
            return .failure(error)
        }
    }

    func getUnreadCount() async -> Result<Int, Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/chat/unread",
                client: client
            )
            let obj = try RepositoryHttp.jsonObject(data)
            let payload = (obj["data"] as? [String: Any]) ?? obj
            let count = RepositoryHttp.optInt(payload, "unread_count", "UnreadCount", "count", "Count")
            return .success(max(0, count))
        } catch {
            return .failure(error)
        }
    }

    private func parseConversations(_ data: Data) -> [ConversationItem] {
        RepositoryHttp.jsonArray(data).map { parseConversationItem($0) }
    }

    private func parseConversationItem(_ o: [String: Any]) -> ConversationItem {
        let myId = sessionStore.read()?.userId ?? ""
        let convId = RepositoryHttp.optString(o, "ID", "id", "conversation_id")
        let buyerId = RepositoryHttp.optString(o, "BuyerID", "buyer_id")
        let sellerId = RepositoryHttp.optString(o, "SellerID", "seller_id")
        let buyerObj = o["Buyer"] as? [String: Any] ?? o["buyer"] as? [String: Any]
        let sellerObj = o["Seller"] as? [String: Any] ?? o["seller"] as? [String: Any]
        let otherProfile: [String: Any]? = {
            if !myId.isEmpty, myId == buyerId { return sellerObj }
            if !myId.isEmpty, myId == sellerId { return buyerObj }
            return sellerObj ?? buyerObj
        }()
        let listingObj = o["Listing"] as? [String: Any]
            ?? o["listing"] as? [String: Any]
            ?? o["product"] as? [String: Any]
        var lastMsgText = ""
        var lastMsgType = "text"
        if let lm = o["LastMessage"] as? [String: Any] ?? o["last_message"] as? [String: Any] {
            lastMsgText = RepositoryHttp.optString(lm, "Content", "content", "Text", "text")
            lastMsgType = RepositoryHttp.optString(lm, "MessageType", "message_type").isEmpty ? "text" : RepositoryHttp.optString(lm, "MessageType", "message_type")
        } else {
            lastMsgText = RepositoryHttp.optString(o, "LastMessage", "last_message")
        }
        let otherId = RepositoryHttp.optString(otherProfile ?? [:], "UserID", "user_id", "id", "ID")
        let username = RepositoryHttp.optString(otherProfile ?? [:], "Username", "username")
        let displayName = RepositoryHttp.optString(otherProfile ?? [:], "DisplayName", "display_name")
        let avatarUrl = RepositoryHttp.optString(otherProfile ?? [:], "AvatarURL", "avatar_url")
        let productId = RepositoryHttp.optString(listingObj ?? [:], "ID", "id")
        let productTitle = RepositoryHttp.optString(listingObj ?? [:], "Title", "title")
        let productPrice = RepositoryHttp.optLong(listingObj ?? [:], "Price", "price")
        let thumb = RepositoryHttp.optString(listingObj ?? [:], "CoverImageURL", "cover_image_url", "thumbnail_url")
        let timestamp = RepositoryHttp.optString(o, "LastMessageAt", "last_message_at", "UpdatedAt", "updated_at")
        let hasUnread = RepositoryHttp.optBool(o, "has_unread", "HasUnread")
        let unreadCount = RepositoryHttp.optInt(o, "unread_count", "UnreadCount")
        return ConversationItem(
            conversationId: convId,
            otherUserId: otherId,
            username: username,
            displayName: displayName.isEmpty ? username : displayName,
            avatarUrl: avatarUrl,
            lastMessageText: lastMsgText,
            lastMessageType: lastMsgType,
            timestamp: timestamp,
            productThumbnailUrl: thumb,
            productTitle: productTitle,
            productId: productId,
            productPrice: productPrice,
            hasUnread: hasUnread,
            unreadCount: unreadCount
        )
    }
}
