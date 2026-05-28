import Foundation

/// Meetup date/time helpers — Android `MeetingUi.kt` (scheduling subset).
enum MeetingUi {
    static func roundUpToNextSlot(from date: Date = Date()) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = comps.minute ?? 0
        let remainder = minute % 15
        var add = remainder == 0 ? 0 : (15 - remainder)
        if remainder == 0, date.timeIntervalSince(cal.date(from: comps) ?? date) > 0 { add = 15 }
        comps.minute = minute + add
        comps.second = 0
        return cal.date(from: comps) ?? date.addingTimeInterval(900)
    }

    static func buildScheduledAtRfc3339(date: Date, hour: Int, minute: Int) -> String {
        var cal = Calendar.current
        cal.timeZone = .current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        let scheduled = cal.date(from: comps) ?? date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        return formatter.string(from: scheduled)
    }

    static func isScheduleInFuture(date: Date, hour: Int, minute: Int) -> Bool {
        var cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        guard let scheduled = cal.date(from: comps) else { return false }
        return scheduled > Date()
    }

    static func formatMeetingWhen(_ iso: String, preferVi: Bool) -> String {
        guard let d = ChatMeetupSchedulingPolicy.parseInstant(iso) else { return iso }
        let fmt = DateFormatter()
        fmt.locale = preferVi ? Locale(identifier: "vi_VN") : Locale(identifier: "en_US")
        fmt.dateFormat = preferVi ? "dd/MM/yyyy · HH:mm" : "MMM d, yyyy · HH:mm"
        return fmt.string(from: d)
    }

    static func isWithinMeetingActionWindow(scheduledAtIso: String, windowMinutes: Int = 30) -> Bool {
        guard let instant = ChatMeetupSchedulingPolicy.parseInstant(scheduledAtIso) else { return false }
        let now = Date()
        let start = instant.addingTimeInterval(TimeInterval(-windowMinutes * 60))
        let end = instant.addingTimeInterval(TimeInterval(windowMinutes * 60))
        return now >= start && now <= end
    }
}
