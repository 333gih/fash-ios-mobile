import Foundation

extension OrderRepository {
    func getOrderDetail(orderId: String) async -> Result<OrderDetailPayload, Error> {
        let id = orderId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/orders/\(id)",
                client: client
            )
            return .success(parseOrderDetail(data))
        } catch {
            return .failure(error)
        }
    }

    func confirmReceipt(orderId: String) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        return await postEmpty(relativePath: "api/v1/orders/\(id)/confirm")
    }

    func cancelOrder(orderId: String, reasonCode: String, reasonNote: String = "") async -> Result<Void, Error> {
        let body: [String: Any] = [
            "reason_code": reasonCode.trimmingCharacters(in: .whitespaces).lowercased(),
            "reason_note": reasonNote.trimmingCharacters(in: .whitespaces),
        ]
        return await postJSONVoid(relativePath: "api/v1/orders/\(orderId.trimmingCharacters(in: .whitespaces))/cancel", body: body)
    }

    private func postEmpty(relativePath: String) async -> Result<Void, Error> {
        let urls = AppEnvironment.coreApiCandidateURLs(relativePath)
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else {
                    throw CoreServiceHttpException(
                        statusCode: http.statusCode,
                        message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                    )
                }
                return .success(())
            } catch {
                lastError = error
            }
        }
        return .failure(lastError)
    }

    private func postJSONVoid(relativePath: String, body: [String: Any]) async -> Result<Void, Error> {
        let urls = AppEnvironment.coreApiCandidateURLs(relativePath)
        var lastError: Error = URLError(.cannotConnectToHost)
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else {
            return .failure(URLError(.cannotParseResponse))
        }
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.httpBody = payload
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else {
                    throw CoreServiceHttpException(
                        statusCode: http.statusCode,
                        message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                    )
                }
                return .success(())
            } catch {
                lastError = error
            }
        }
        return .failure(lastError)
    }

    private func parseOrderDetail(_ data: Data) -> OrderDetailPayload {
        guard let top = try? RepositoryHttp.jsonObject(data) else { return OrderDetailPayload() }
        let o = unwrapOrderObject(top)
        let listing = (o["listing"] as? [String: Any]) ?? (o["Listing"] as? [String: Any]) ?? [:]
        let buyer = (o["buyer"] as? [String: Any]) ?? (o["Buyer"] as? [String: Any]) ?? [:]
        let seller = (o["seller"] as? [String: Any]) ?? (o["Seller"] as? [String: Any]) ?? [:]
        let imageUrls = listing["image_urls"] as? [String] ?? listing["ImageURLs"] as? [String]
        var cover = RepositoryHttp.optString(listing, "cover_image_url", "CoverImageURL")
        if cover.isEmpty, let first = imageUrls?.first { cover = first }
        let rawStatus = RepositoryHttp.optString(o, "status", "Status").lowercased()
        let canConfirm = RepositoryHttp.optBool(o, "can_confirm", "CanConfirm", default: rawStatus == "in_transit")
        let buyerReview = parseBuyerReview(o)
        let apiCanReview = o["can_review"] != nil
            ? RepositoryHttp.optBool(o, "can_review", "CanReview", default: false)
            : (o["CanReview"] != nil ? RepositoryHttp.optBool(o, "CanReview", default: false) : nil)
        let canReview: Bool = {
            if buyerReview != nil { return false }
            if let explicit = apiCanReview { return explicit }
            return rawStatus == "delivered_confirmed"
        }()
        let shipAddr = (o["shipping_address"] as? [String: Any])
            ?? (o["ShippingAddress"] as? [String: Any])
            ?? (o["delivery_address"] as? [String: Any])
            ?? [:]
        var shippingFormatted = formatShippingAddress(shipAddr, order: o)
        if shippingFormatted.isEmpty { shippingFormatted = formatFlatShipping(o) }
        let shipment = (o["shipment"] as? [String: Any]) ?? (o["Shipment"] as? [String: Any]) ?? [:]
        var tracking = RepositoryHttp.optString(o, "tracking_number", "TrackingNumber")
        let trackingFromShipment = RepositoryHttp.optString(shipment, "tracking_number", "TrackingNumber")
        if tracking.isEmpty, !trackingFromShipment.isEmpty { tracking = trackingFromShipment }
        let trackingSummary = RepositoryHttp.optString(shipment, "tracking_status", "TrackingStatus")
            .ifEmpty(RepositoryHttp.optString(o, "tracking_status", "TrackingStatus", "last_tracking_event"))
        let canShip = RepositoryHttp.optBool(o, "can_ship", "CanShip", default: false)
            || (rawStatus == "payment_held" && tracking.isEmpty)
        return OrderDetailPayload(
            orderId: RepositoryHttp.optString(o, "id", "ID", "order_id"),
            listingId: RepositoryHttp.optString(o, "listing_id", "ListingID")
                .ifEmpty(RepositoryHttp.optString(listing, "id", "ID")),
            buyerUserId: RepositoryHttp.optString(o, "buyer_id", "BuyerID")
                .ifEmpty(RepositoryHttp.optString(buyer, "user_id", "UserID", "id", "ID")),
            sellerUserId: RepositoryHttp.optString(o, "seller_id", "SellerID")
                .ifEmpty(RepositoryHttp.optString(seller, "user_id", "UserID", "id", "ID")),
            amountVnd: RepositoryHttp.optLong(o, "amount_vnd", "AmountVND"),
            platformFeeVnd: RepositoryHttp.optLong(o, "platform_fee_vnd", "PlatformFeeVND"),
            sellerPayoutVnd: RepositoryHttp.optLong(o, "seller_payout_vnd", "SellerPayoutVND"),
            status: rawStatus.isEmpty ? "payment_pending" : rawStatus,
            fulfillmentChannel: RepositoryHttp.optString(o, "fulfillment_channel", "FulfillmentChannel").lowercased(),
            trackingNumber: tracking,
            carrier: RepositoryHttp.optString(o, "carrier", "Carrier"),
            listingTitle: RepositoryHttp.optString(listing, "title", "Title"),
            listingImageUrl: cover,
            listingPriceVnd: RepositoryHttp.optLong(listing, "price", "Price"),
            listingStatus: RepositoryHttp.optString(listing, "status", "Status").lowercased().ifEmpty("active"),
            sellerUsername: RepositoryHttp.optString(seller, "username", "Username"),
            sellerDisplayName: RepositoryHttp.optString(seller, "display_name", "DisplayName"),
            sellerAvatarUrl: RepositoryHttp.optString(seller, "avatar_url", "AvatarURL"),
            buyerUsername: RepositoryHttp.optString(buyer, "username", "Username"),
            buyerDisplayName: RepositoryHttp.optString(buyer, "display_name", "DisplayName"),
            buyerAvatarUrl: RepositoryHttp.optString(buyer, "avatar_url", "AvatarURL"),
            conversationId: RepositoryHttp.optString(o, "conversation_id", "conversationId", "ConversationID"),
            canConfirmReceipt: canConfirm,
            canCancel: RepositoryHttp.optBool(o, "can_cancel", "CanCancel", default: false),
            canReview: canReview,
            shippingFeeVnd: RepositoryHttp.optLong(o, "shipping_fee_vnd", "ShippingFeeVND", "shipping_fee"),
            discountVnd: RepositoryHttp.optLong(o, "discount_vnd", "DiscountVND", "discount_amount_vnd"),
            buyerTotalVnd: RepositoryHttp.optLong(o, "buyer_total_vnd", "BuyerTotalVND", "total_vnd"),
            recipientName: RepositoryHttp.optString(shipAddr, "recipient_name", "name", "RecipientName")
                .ifEmpty(RepositoryHttp.optString(o, "recipient_name", "RecipientName")),
            recipientPhone: RepositoryHttp.optString(shipAddr, "phone", "Phone")
                .ifEmpty(RepositoryHttp.optString(o, "recipient_phone", "RecipientPhone")),
            shippingAddressFormatted: shippingFormatted,
            createdAt: optIso(o, "created_at", "CreatedAt", "createdAt"),
            paidAt: optIso(o, "paid_at", "PaidAt", "payment_completed_at"),
            shippedAt: optIso(o, "shipped_at", "ShippedAt", "ship_date"),
            deliveredAt: optIso(o, "delivered_at", "DeliveredAt", "buyer_confirmed_at"),
            cancelledAt: optIso(o, "cancelled_at", "CancelledAt", "canceled_at"),
            expectedDeliveryAt: optIso(o, "expected_delivery_at", "ExpectedDelivery", "estimated_delivery"),
            shipByAt: optIso(o, "ship_by", "ship_by_at", "ShipBy", "must_ship_before"),
            escrowReleaseAt: optIso(o, "escrow_release_at", "EscrowReleaseAt", "auto_release_at"),
            disputeSummary: RepositoryHttp.optString(o, "dispute_summary", "dispute_reason", "DisputeSummary"),
            listingVariantLabel: buildVariantLabel(listing),
            trackingStatusSummary: trackingSummary,
            canShip: canShip,
            canConfirmHandoff: RepositoryHttp.optBool(o, "can_confirm_handoff", "CanConfirmHandoff", default: false),
            canAcknowledgeOfflineCash: RepositoryHttp.optBool(o, "can_acknowledge_offline_cash", "CanAcknowledgeOfflineCash", default: false),
            meetupDeadlineAt: optIso(o, "meetup_deadline_at", "MeetupDeadlineAt"),
            orderExpiresAt: optIso(o, "order_expires_at", "OrderExpiresAt"),
            remainingSeconds: RepositoryHttp.optLong(o, "remaining_seconds", "RemainingSeconds"),
            expiryKind: RepositoryHttp.optString(o, "expiry_kind", "ExpiryKind").lowercased(),
            meetingAppointment: parseMeetingAppointment(o),
            meetingGrace: parseMeetingGrace(o),
            buyerReview: buyerReview
        )
    }

    private func unwrapOrderObject(_ top: [String: Any]) -> [String: Any] {
        if let data = top["data"] as? [String: Any] { return data }
        if let order = top["order"] as? [String: Any] { return order }
        return top
    }

    private func optIso(_ o: [String: Any], _ keys: String...) -> String {
        for key in keys {
            let v = (o[key] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
            if !v.isEmpty { return v }
        }
        return ""
    }

    private func parseBuyerReview(_ o: [String: Any]) -> OrderBuyerReview? {
        let r = (o["buyer_review"] as? [String: Any]) ?? (o["BuyerReview"] as? [String: Any])
        guard let r else { return nil }
        let id = RepositoryHttp.optString(r, "id", "ID")
        let rating = RepositoryHttp.optInt(r, "rating", "Rating")
        if id.isEmpty, rating == 0 { return nil }
        return OrderBuyerReview(
            id: id,
            rating: rating,
            comment: RepositoryHttp.optString(r, "comment", "Comment"),
            createdAt: RepositoryHttp.optString(r, "created_at", "CreatedAt")
        )
    }

    private func parseMeetingAppointment(_ o: [String: Any]) -> OrderMeetingAppointment? {
        let m = (o["meeting_appointment"] as? [String: Any]) ?? (o["MeetingAppointment"] as? [String: Any])
        guard let m else { return nil }
        let id = RepositoryHttp.optString(m, "id", "ID")
        guard !id.isEmpty else { return nil }
        return OrderMeetingAppointment(
            id: id,
            status: RepositoryHttp.optString(m, "status", "Status"),
            locationUrl: RepositoryHttp.optString(m, "location_url", "LocationURL"),
            scheduledAt: optIso(m, "scheduled_at", "ScheduledAt"),
            reminderOffsetMinutes: RepositoryHttp.optInt(m, "reminder_offset_minutes", default: 0),
            reminderEnabled: RepositoryHttp.optBool(m, "reminder_enabled", default: false),
            reminderSentAt: RepositoryHttp.optString(m, "reminder_sent_at", "ReminderSentAt"),
            createdAt: RepositoryHttp.optString(m, "created_at", "CreatedAt"),
            updatedAt: RepositoryHttp.optString(m, "updated_at", "UpdatedAt"),
            buyerCheckInAt: RepositoryHttp.optString(m, "buyer_check_in_at", "BuyerCheckInAt"),
            sellerCheckInAt: RepositoryHttp.optString(m, "seller_check_in_at", "SellerCheckInAt")
        )
    }

    private func parseMeetingGrace(_ o: [String: Any]) -> OrderMeetingGrace? {
        let g = (o["meeting_grace"] as? [String: Any]) ?? (o["MeetingGrace"] as? [String: Any])
        guard let g else { return nil }
        return OrderMeetingGrace(
            canCheckIn: RepositoryHttp.optBool(g, "can_check_in", default: false),
            selfCheckedIn: RepositoryHttp.optBool(g, "self_checked_in", default: false),
            canReportNoShow: RepositoryHttp.optBool(g, "can_report_no_show", default: false),
            sosUnlocked: RepositoryHttp.optBool(g, "sos_unlocked", default: false),
            checkInHint: RepositoryHttp.optString(g, "check_in_hint"),
            noShowHint: RepositoryHttp.optString(g, "no_show_hint"),
            buyerCheckedInAt: RepositoryHttp.optString(g, "buyer_checked_in_at"),
            sellerCheckedInAt: RepositoryHttp.optString(g, "seller_checked_in_at"),
            phase: RepositoryHttp.optString(g, "phase")
        )
    }

    private func formatShippingAddress(_ ship: [String: Any], order: [String: Any]) -> String {
        let parts = [
            RepositoryHttp.optString(ship, "line1", "Line1", "address_line1"),
            RepositoryHttp.optString(ship, "line2", "Line2", "address_line2"),
            RepositoryHttp.optString(ship, "ward", "Ward"),
            RepositoryHttp.optString(ship, "district", "District"),
            RepositoryHttp.optString(ship, "city", "City", "province"),
        ].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if !parts.isEmpty { return parts.joined(separator: ", ") }
        return RepositoryHttp.optString(ship, "formatted", "Formatted")
    }

    private func formatFlatShipping(_ order: [String: Any]) -> String {
        let parts = [
            RepositoryHttp.optString(order, "shipping_line1", "ShippingLine1"),
            RepositoryHttp.optString(order, "shipping_line2", "ShippingLine2"),
            RepositoryHttp.optString(order, "shipping_city", "ShippingCity"),
        ].filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }

    private func buildVariantLabel(_ listing: [String: Any]) -> String {
        let size = RepositoryHttp.optString(listing, "size", "Size")
        let brand = RepositoryHttp.optString(listing, "brand", "Brand")
        let parts = [size, brand].filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespaces).isEmpty ? fallback : self
    }
}
