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
}
