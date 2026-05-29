import Foundation

/// Meetup scheduling policy — Android `ChatMeetupSchedulingPolicy.kt`.
enum ChatMeetupSchedulingPolicy {
    static func parseInstant(_ raw: String) -> Date? {
        ChatInstantParse.parse(raw)
    }

    static func isMeetupSlotStillUpcoming(status: String, scheduledAtRaw: String, now: Date = Date()) -> Bool {
        let st = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard st == "pending" || st == "confirmed" else { return false }
        guard let at = parseInstant(scheduledAtRaw) else { return true }
        return at >= now
    }

    static func dealBannerShouldHideScheduleMeetup(
        orderStatus: String?,
        orderApptStatus: String?,
        orderApptScheduledAt: String? = nil,
        messages: [ChatMessage]
    ) -> Bool {
        let ord = orderStatus?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if ord == "delivered_confirmed" || ord == "disputed" { return true }

        let oStRaw = orderApptStatus?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let oSt = oStRaw.lowercased()
        if oSt == "pending" || oSt == "confirmed" { return true }
        if !oStRaw.isEmpty { return false }

        let latest = messages
            .filter { $0.messageType.lowercased() == "meeting_proposal" }
            .max(by: { $0.timestamp < $1.timestamp })
        let apSt = latest?.meetingAppointment?.status.lowercased() ?? ""
        return apSt == "pending" || apSt == "confirmed"
    }

    static func hasActiveFutureMeetupBlockingReschedule(
        orderStatus: String?,
        orderApptStatus: String?,
        orderApptScheduledAt: String?,
        messages: [ChatMessage],
        now: Date = Date()
    ) -> Bool {
        let ord = orderStatus?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if ord != "cancelled" {
            let oSt = orderApptStatus?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let oAt = orderApptScheduledAt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !oSt.isEmpty, !oAt.isEmpty, isMeetupSlotStillUpcoming(status: oSt, scheduledAtRaw: oAt, now: now) {
                return true
            }
        }
        return messages.contains { msg in
            guard msg.messageType.lowercased() == "meeting_proposal",
                  let ap = msg.meetingAppointment else { return false }
            return isMeetupSlotStillUpcoming(status: ap.status, scheduledAtRaw: ap.scheduledAt, now: now)
        }
    }

    static func conversationHadBuyerOfferAndSellerCounter(messages: [ChatMessage], viewerIsBuyer: Bool) -> Bool {
        let hasBuyerOffer = messages.contains { m in
            m.messageType == "offer" && (viewerIsBuyer ? m.isFromMe : !m.isFromMe)
        }
        let hasSellerCounter = messages.contains { m in
            m.messageType.lowercased() == "counter_offer" && (viewerIsBuyer ? !m.isFromMe : m.isFromMe)
        }
        return hasBuyerOffer && hasSellerCounter
    }

    static func shouldBlockBuyerNewPriceOffer(
        messages: [ChatMessage],
        viewerIsBuyer: Bool,
        orderStatus: String?,
        orderApptStatus: String?,
        orderApptScheduledAt: String?
    ) -> Bool {
        guard viewerIsBuyer else { return false }
        guard conversationHadBuyerOfferAndSellerCounter(messages: messages, viewerIsBuyer: true) else { return false }
        return hasActiveFutureMeetupBlockingReschedule(
            orderStatus: orderStatus,
            orderApptStatus: orderApptStatus,
            orderApptScheduledAt: orderApptScheduledAt,
            messages: messages
        )
    }
}
