import Foundation

extension ChatRepository {
    // MARK: - Offers

    func createOffer(conversationId: String, amountVnd: Int64) async -> Result<PriceOffer, Error> {
        do {
            let data = try await postJSON(relativePath: "api/v1/chat/offers", body: [
                "conversation_id": conversationId.trimmingCharacters(in: .whitespaces),
                "amount_vnd": amountVnd,
            ])
            return .success(parseOfferData(data))
        } catch {
            return .failure(error)
        }
    }

    func createCounterOffer(conversationId: String, buyerOfferMessageId: String, amountVnd: Int64) async -> Result<ChatMessage, Error> {
        do {
            let data = try await postJSON(relativePath: "api/v1/chat/offers/counter", body: [
                "conversation_id": conversationId.trimmingCharacters(in: .whitespaces),
                "buyer_offer_message_id": buyerOfferMessageId.trimmingCharacters(in: .whitespaces),
                "amount_vnd": amountVnd,
            ])
            return .success(parseSingleMessage(data))
        } catch {
            return .failure(error)
        }
    }

    func acceptOfferUnified(conversationId: String, offerMessageId: String) async -> Result<String?, Error> {
        do {
            let data = try await postJSON(relativePath: "api/v1/chat/offers/accept-in-chat", body: [
                "conversation_id": conversationId.trimmingCharacters(in: .whitespaces),
                "offer_message_id": offerMessageId.trimmingCharacters(in: .whitespaces),
            ])
            return .success(parseOrderIdFromOfferAcceptResponse(data))
        } catch let error as CoreServiceHttpException where error.statusCode == 404 {
            return await respondToOffer(conversationId: conversationId, offerMessageId: offerMessageId, accept: true)
        } catch {
            return .failure(error)
        }
    }

    func respondToOffer(conversationId: String, offerMessageId: String, accept: Bool) async -> Result<String?, Error> {
        let path = accept ? "api/v1/chat/offers/accept" : "api/v1/chat/offers/decline"
        do {
            let data = try await postJSON(relativePath: path, body: [
                "conversation_id": conversationId.trimmingCharacters(in: .whitespaces),
                "offer_message_id": offerMessageId.trimmingCharacters(in: .whitespaces),
            ])
            return .success(accept ? parseOrderIdFromOfferAcceptResponse(data) : nil)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Offer parsing helpers

    func parseOfferData(_ data: Data) -> PriceOffer {
        let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
        let payload = (obj["data"] as? [String: Any]) ?? obj
        return parseOfferObj(payload)
    }

    func parseSingleMessage(_ data: Data) -> ChatMessage {
        let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
        let payload = (obj["data"] as? [String: Any])
            ?? (obj["message"] as? [String: Any])
            ?? (obj["Message"] as? [String: Any])
            ?? obj
        return parseMessageObj(payload)
    }

    func parseOrderIdFromOfferAcceptResponse(_ data: Data) -> String? {
        let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
        let payload = (obj["data"] as? [String: Any]) ?? obj
        if let orderObj = payload["order"] as? [String: Any] ?? payload["Order"] as? [String: Any] {
            let nested = RepositoryHttp.optString(orderObj, "id", "ID")
            if !nested.isEmpty { return nested }
        }
        let direct = RepositoryHttp.optString(payload, "order_id", "OrderID", "orderId")
        return direct.isEmpty ? nil : direct
    }

    func parseOfferObj(_ o: [String: Any]) -> PriceOffer {
        let myId = sessionStore.read()?.userId ?? ""
        let senderId = RepositoryHttp.optString(o, "SenderID", "sender_id")
        let proposedByMe: Bool = {
            if !senderId.isEmpty, !myId.isEmpty { return senderId == myId }
            return RepositoryHttp.optBool(o, "proposed_by_me", "from_me")
        }()
        return PriceOffer(
            offerId: RepositoryHttp.optString(o, "ID", "id", "offer_id", "message_id"),
            amountVnd: RepositoryHttp.optLong(o, "AmountVND", "amount_vnd", "amount"),
            status: RepositoryHttp.optString(o, "Status", "status").ifEmpty("pending"),
            proposedByMe: proposedByMe
        )
    }

    func parseMeetingAppointmentPayload(_ m: [String: Any]) -> MeetingAppointmentPayload? {
        guard let o = m["meeting_appointment"] as? [String: Any]
            ?? m["MeetingAppointment"] as? [String: Any] else { return nil }
        let id = RepositoryHttp.optString(o, "id", "ID")
        guard !id.isEmpty else { return nil }
        let myId = sessionStore.read()?.userId ?? ""
        let proposerId = RepositoryHttp.optString(o, "proposer_id", "ProposerID")
        return MeetingAppointmentPayload(
            appointmentId: id,
            status: RepositoryHttp.optString(o, "status", "Status").lowercased().ifEmpty("pending"),
            locationUrl: RepositoryHttp.optString(o, "location_url", "LocationURL"),
            scheduledAt: RepositoryHttp.optString(o, "scheduled_at", "ScheduledAt"),
            reminderOffsetMinutes: RepositoryHttp.optInt(o, "reminder_offset_minutes", "ReminderOffsetMinutes", default: 60),
            reminderEnabled: RepositoryHttp.optBool(o, "reminder_enabled", "ReminderEnabled", default: true),
            proposerId: proposerId,
            isProposerMe: !myId.isEmpty && !proposerId.isEmpty && proposerId == myId,
            buyerCheckInAt: RepositoryHttp.optString(o, "buyer_check_in_at", "BuyerCheckInAt"),
            sellerCheckInAt: RepositoryHttp.optString(o, "seller_check_in_at", "SellerCheckInAt"),
            buyerOnMyWayAt: RepositoryHttp.optString(o, "buyer_on_my_way_at", "BuyerOnMyWayAt"),
            sellerOnMyWayAt: RepositoryHttp.optString(o, "seller_on_my_way_at", "SellerOnMyWayAt"),
            safeZoneName: RepositoryHttp.optString(o, "safe_zone_name", "SafeZoneName")
        )
    }

    func parseMyConversationReport(_ root: [String: Any]) -> MyConversationReport? {
        let o = root["my_report"] as? [String: Any] ?? root["MyReport"] as? [String: Any] ?? [:]
        let reportId = RepositoryHttp.optString(o, "report_id", "ReportID", "id", "ID")
        guard !reportId.isEmpty else { return nil }
        return MyConversationReport(
            reportId: reportId,
            reportedUserId: RepositoryHttp.optString(o, "reported_user_id", "ReportedUserID"),
            category: RepositoryHttp.optString(o, "category", "Category").lowercased(),
            createdAt: RepositoryHttp.optString(o, "created_at", "CreatedAt"),
            status: RepositoryHttp.optString(o, "status", "Status").lowercased().ifEmpty("pending")
        )
    }
}

private extension RepositoryHttp {
    static func optBool(_ o: [String: Any], _ keys: String..., default defaultValue: Bool = false) -> Bool {
        for key in keys {
            if let b = o[key] as? Bool { return b }
        }
        return defaultValue
    }

    static func optInt(_ o: [String: Any], _ keys: String..., default defaultValue: Int = 0) -> Int {
        for key in keys {
            if let n = o[key] as? NSNumber { return n.intValue }
        }
        return defaultValue
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}
