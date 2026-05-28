import Foundation

/// Chat/conversations API — Android [ChatRepository] (inbox list).
final class ChatRepository {
    private let client: SecuredApiClient
    private let sessionStore: AuthSessionStore

    init(client: SecuredApiClient, sessionStore: AuthSessionStore) {
        self.client = client
        self.sessionStore = sessionStore
    }

    var currentUserId: String {
        sessionStore.read()?.userId ?? ""
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

    func getConversationsGroupedByListing(limit: Int = 50, offset: Int = 0) async -> Result<[ConversationListingGroup], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/chat/conversations?limit=\(limit)&offset=\(offset)&group_by=listing",
                client: client
            )
            return .success(parseConversationGroups(data))
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

    func getConversationDetail(conversationId: String) async -> Result<ConversationDetail, Error> {
        let id = conversationId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/chat/conversations/\(id)",
                client: client
            )
            return .success(parseConversationDetail(data))
        } catch {
            return .failure(error)
        }
    }

    func getMessages(conversationId: String, limit: Int = 50, offset: Int = 0) async -> Result<[ChatMessage], Error> {
        let id = conversationId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/chat/conversations/\(id)/messages?limit=\(limit)&offset=\(offset)",
                client: client
            )
            return .success(parseMessages(data))
        } catch {
            return .failure(error)
        }
    }

    func sendMessage(conversationId: String, text: String) async -> Result<ChatMessage, Error> {
        let body: [String: Any] = [
            "conversation_id": conversationId,
            "content": text,
        ]
        do {
            let data = try await postJSON(relativePath: "api/v1/chat/messages", body: body)
            let rows = parseMessages(data)
            if let first = rows.first { return .success(first) }
            let obj = try RepositoryHttp.jsonObject(data)
            let payload = (obj["data"] as? [String: Any]) ?? obj
            return .success(parseMessageObj(payload))
        } catch {
            return .failure(error)
        }
    }

    func startConversation(listingId: String) async -> Result<String, Error> {
        do {
            let data = try await postJSON(relativePath: "api/v1/chat/conversations", body: ["listing_id": listingId])
            let root = try RepositoryHttp.jsonObject(data)
            let payload = (root["data"] as? [String: Any]) ?? root
            if let id = payload["id"] as? String, !id.isEmpty { return .success(id) }
            if let id = payload["ID"] as? String, !id.isEmpty { return .success(id) }
            if let nested = payload["conversation"] as? [String: Any] {
                let id = RepositoryHttp.optString(nested, "id", "ID", "conversation_id")
                if !id.isEmpty { return .success(id) }
            }
            let direct = RepositoryHttp.optString(root, "id", "ID", "conversation_id")
            guard !direct.isEmpty else { return .failure(URLError(.cannotParseResponse)) }
            return .success(direct)
        } catch {
            return .failure(error)
        }
    }

    func markConversationRead(conversationId: String) async -> Result<Void, Error> {
        let encoded = conversationId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? conversationId
        do {
            _ = try await postJSON(relativePath: "api/v1/chat/conversations/\(encoded)/read", body: [:], method: "POST")
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func postJSON(relativePath: String, body: [String: Any], method: String = "POST") async throws -> Data {
        let urls = AppEnvironment.coreApiCandidateURLs(relativePath)
        var lastError: Error = URLError(.cannotConnectToHost)
        let payload = body.isEmpty ? Data("{}".utf8) : try JSONSerialization.data(withJSONObject: body)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = method
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = payload
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else {
                    throw CoreServiceHttpException(
                        statusCode: http.statusCode,
                        message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                    )
                }
                return data
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private func parseConversationDetail(_ data: Data) -> ConversationDetail {
        let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
        let dataObj = (obj["data"] as? [String: Any]) ?? obj
        let root = (dataObj["conversation"] as? [String: Any])
            ?? (dataObj["Conversation"] as? [String: Any])
            ?? dataObj
        let myId = sessionStore.read()?.userId ?? ""
        let convId = RepositoryHttp.optString(root, "ID", "id", "conversation_id")
        let buyerId = RepositoryHttp.optString(root, "BuyerID", "buyer_id")
        let sellerId = RepositoryHttp.optString(root, "SellerID", "seller_id")
        let buyerObj = root["Buyer"] as? [String: Any] ?? root["buyer"] as? [String: Any]
        let sellerObj = root["Seller"] as? [String: Any] ?? root["seller"] as? [String: Any]
        let otherProfile: [String: Any]? = {
            if !myId.isEmpty, myId == buyerId { return sellerObj }
            if !myId.isEmpty, myId == sellerId { return buyerObj }
            return sellerObj ?? buyerObj
        }()
        let otherUser = parseOtherUser(otherProfile ?? root["other_user"] as? [String: Any] ?? [:])
        let listingObj = root["Listing"] as? [String: Any]
            ?? root["listing"] as? [String: Any]
            ?? root["product"] as? [String: Any]
        let product = listingObj.map(parseProductCard)
        let isBuyer: Bool = {
            if !myId.isEmpty, !buyerId.isEmpty { return myId == buyerId }
            return true
        }()
        let orderId = RepositoryHttp.optString(root, "order_id", "OrderID").nilIfEmpty
        let offerCount = RepositoryHttp.optInt(root, "offer_count", "OfferCount")
        let isClosed = RepositoryHttp.optBool(root, "is_closed", "IsClosed")
        let pendingOffer = (root["pending_offer"] as? [String: Any]).map(parseOfferObj)
        let myReport = parseMyConversationReport(root)
        return ConversationDetail(
            conversationId: convId,
            otherUser: otherUser,
            product: product,
            isBuyer: isBuyer,
            orderId: orderId,
            offerCount: offerCount,
            isClosed: isClosed,
            pendingOffer: pendingOffer,
            myReport: myReport
        )
    }

    private func parseOtherUser(_ o: [String: Any]) -> ChatOtherUser {
        ChatOtherUser(
            userId: RepositoryHttp.optString(o, "UserID", "user_id", "id", "ID"),
            displayName: RepositoryHttp.optString(o, "DisplayName", "display_name"),
            username: RepositoryHttp.optString(o, "Username", "username"),
            avatarUrl: RepositoryHttp.optString(o, "AvatarURL", "avatar_url")
        )
    }

    private func parseProductCard(_ p: [String: Any]) -> ChatProductCard {
        let imageUrls = p["ImageURLs"] as? [String] ?? p["image_urls"] as? [String]
        let cover = RepositoryHttp.optString(p, "CoverImageURL", "cover_image_url", "thumbnail_url", "image_url")
        let imageUrl = cover.isEmpty ? (imageUrls?.first ?? "") : cover
        let status = RepositoryHttp.optString(p, "Status", "status", "listing_status").lowercased().ifEmpty("active")
        return ChatProductCard(
            listingId: RepositoryHttp.optString(p, "ID", "id", "listing_id"),
            title: RepositoryHttp.optString(p, "Title", "title"),
            priceVnd: RepositoryHttp.optLong(p, "Price", "price", "price_vnd"),
            imageUrl: imageUrl,
            listingStatus: status
        )
    }

    private func parseMessages(_ data: Data) -> [ChatMessage] {
        let rows = RepositoryHttp.jsonArray(data)
        let parsed: [ChatMessage]
        if !rows.isEmpty {
            parsed = rows.map(parseMessageObj)
        } else if let root = try? RepositoryHttp.jsonObject(data),
                  let arr = root["messages"] as? [[String: Any]] {
            parsed = arr.map(parseMessageObj)
        } else {
            return []
        }
        return parsed
            .filter { m in
                // skip deleted rows if API sends flag
                true
            }
            .reduce(into: [String: ChatMessage]()) { acc, msg in
                acc[msg.messageId] = msg
            }
            .values
            .sorted { $0.timestamp < $1.timestamp }
    }

    private func parseSingleMessageLegacy(_ data: Data) -> ChatMessage {
        let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
        let payload = (obj["data"] as? [String: Any]) ?? obj
        return parseMessageObj(payload)
    }

    func parseMessageObj(_ m: [String: Any]) -> ChatMessage {
        let myId = sessionStore.read()?.userId ?? ""
        let senderId = RepositoryHttp.optString(m, "SenderID", "sender_id")
        let isFromMe: Bool = {
            if let b = m["IsFromMe"] as? Bool { return b }
            if let b = m["is_from_me"] as? Bool { return b }
            if let b = m["from_me"] as? Bool { return b }
            if !myId.isEmpty, !senderId.isEmpty { return senderId == myId }
            return false
        }()
        let rawType = RepositoryHttp.optString(m, "MessageType", "message_type", "Type", "type").ifEmpty("text")
        let systemSubtype = RepositoryHttp.optString(m, "system_subtype", "system_type", "SystemSubtype").nilIfEmpty
        let isRead: Bool = {
            if m["ReadAt"] != nil && !(m["ReadAt"] is NSNull) { return true }
            if m["read_at"] != nil && !(m["read_at"] is NSNull) { return true }
            return RepositoryHttp.optBool(m, "IsRead", "is_read")
        }()
        return ChatMessage(
            messageId: RepositoryHttp.optString(m, "ID", "id", "message_id"),
            text: RepositoryHttp.optString(m, "Content", "content", "text", "Text"),
            isFromMe: isFromMe,
            timestamp: RepositoryHttp.optString(m, "CreatedAt", "created_at", "timestamp", "sent_at"),
            isRead: isRead,
            senderId: senderId,
            messageType: rawType,
            offerAmountVnd: RepositoryHttp.optLong(m, "OfferAmountVND", "offer_amount_vnd"),
            offerStatus: RepositoryHttp.optString(m, "OfferStatus", "offer_status").lowercased().ifEmpty("pending"),
            outboundState: .none,
            systemSubtype: systemSubtype,
            meetingAppointment: parseMeetingAppointmentPayload(m)
        )
    }

    private func parseConversations(_ data: Data) -> [ConversationItem] {
        RepositoryHttp.jsonArray(data).map { parseConversationItem($0) }
    }

    private func parseConversationGroups(_ data: Data) -> [ConversationListingGroup] {
        let arr = RepositoryHttp.jsonArray(data)
        if arr.isEmpty, let root = try? RepositoryHttp.jsonObject(data) {
            let nested = (root["data"] as? [[String: Any]])
                ?? (root["groups"] as? [[String: Any]])
                ?? []
            if !nested.isEmpty {
                return parseConversationGroupsFromRows(nested)
            }
        }
        if arr.isEmpty { return [] }
        return parseConversationGroupsFromRows(arr)
    }

    private func parseConversationGroupsFromRows(_ arr: [[String: Any]]) -> [ConversationListingGroup] {
        guard let sample = arr.first else { return [] }
        let groupedShape = sample["conversations"] != nil
            || sample["Conversations"] != nil
            || sample["listing"] != nil
            || sample["Listing"] != nil
        if groupedShape {
            return arr.compactMap { g in
                let listingObj = (g["listing"] as? [String: Any]) ?? (g["Listing"] as? [String: Any])
                let convArr = (g["conversations"] as? [[String: Any]])
                    ?? (g["Conversations"] as? [[String: Any]])
                    ?? []
                let listingId: String = {
                    if let lo = listingObj {
                        let id = RepositoryHttp.optString(lo, "ID", "id", "listing_id")
                        if !id.isEmpty { return id }
                    }
                    return RepositoryHttp.optString(g, "listing_id", "ListingID")
                }()
                guard !listingId.isEmpty else { return nil }
                let card = listingObj.map(parseProductCard)
                let conversations = convArr.map(parseConversationItem)
                let count = RepositoryHttp.optInt(g, "conversation_count", "ConversationCount")
                let badge = count > 0 ? count : conversations.count
                return ConversationListingGroup(
                    listingId: listingId,
                    coverImageUrl: card?.imageUrl ?? conversations.first?.productThumbnailUrl ?? "",
                    title: card?.title ?? conversations.first?.productTitle ?? "",
                    priceVnd: card?.priceVnd ?? conversations.first?.productPrice ?? 0,
                    conversations: conversations,
                    conversationCountBadge: badge
                )
            }
        }
        let flat = arr.map(parseConversationItem)
        return flat
            .filter { !$0.productId.isEmpty }
            .reduce(into: [String: [ConversationItem]]()) { acc, item in
                acc[item.productId, default: []].append(item)
            }
            .map { pid, rows in
                let first = rows[0]
                let sorted = rows.sorted { $0.timestamp > $1.timestamp }
                return ConversationListingGroup(
                    listingId: pid,
                    coverImageUrl: first.productThumbnailUrl,
                    title: first.productTitle,
                    priceVnd: first.productPrice,
                    conversations: sorted,
                    conversationCountBadge: sorted.count
                )
            }
            .sorted {
                ($0.conversations.map(\.timestamp).max() ?? "") > ($1.conversations.map(\.timestamp).max() ?? "")
            }
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
        var lastOfferAmountVnd: Int64 = 0
        var lastOfferFromBuyer = true
        if let lm = o["LastMessage"] as? [String: Any] ?? o["last_message"] as? [String: Any] {
            lastMsgText = RepositoryHttp.optString(lm, "Content", "content", "Text", "text")
            lastMsgType = RepositoryHttp.optString(lm, "MessageType", "message_type").isEmpty ? "text" : RepositoryHttp.optString(lm, "MessageType", "message_type")
            lastOfferAmountVnd = RepositoryHttp.optLong(lm, "OfferAmountVND", "offer_amount_vnd")
            let senderId = RepositoryHttp.optString(lm, "SenderID", "sender_id")
            if !senderId.isEmpty, !buyerId.isEmpty {
                lastOfferFromBuyer = senderId == buyerId
            }
        } else {
            lastMsgText = RepositoryHttp.optString(o, "LastMessage", "last_message")
        }
        let overrideType = RepositoryHttp.optString(o, "LastMessageType", "last_message_type")
        if !overrideType.isEmpty { lastMsgType = overrideType }
        if lastOfferAmountVnd == 0 {
            lastOfferAmountVnd = RepositoryHttp.optLong(o, "LastOfferAmountVND", "last_offer_amount_vnd")
        }
        if lastOfferAmountVnd > 0 { lastMsgType = "offer" }
        let pendingOfferObj = o["pending_offer"] as? [String: Any] ?? o["PendingOffer"] as? [String: Any]
        let pendingOfferAmountVnd: Int64 = {
            if let po = pendingOfferObj {
                return RepositoryHttp.optLong(po, "AmountVND", "amount_vnd", "Amount")
            }
            return RepositoryHttp.optLong(o, "PendingOfferAmountVND", "pending_offer_amount_vnd")
        }()
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
            unreadCount: unreadCount,
            buyerUserId: buyerId,
            sellerUserId: sellerId,
            lastOfferAmountVnd: lastOfferAmountVnd,
            lastOfferFromBuyer: lastOfferFromBuyer,
            pendingOfferAmountVnd: pendingOfferAmountVnd
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
