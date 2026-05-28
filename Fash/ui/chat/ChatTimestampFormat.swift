import Foundation

enum ChatTimestampFormat {
    static func format(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let toParse: String = {
            if trimmed.contains("T") { return trimmed }
            if trimmed.contains(" ") { return trimmed.replacingOccurrences(of: " ", with: "T") }
            if trimmed.count == 10 { return "\(trimmed)T00:00:00Z" }
            return trimmed
        }()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var instant = formatter.date(from: toParse)
        if instant == nil {
            formatter.formatOptions = [.withInternetDateTime]
            instant = formatter.date(from: toParse)
        }
        guard let date = instant else { return String(trimmed.prefix(16)) }

        let now = Date()
        let diff = now.timeIntervalSince(date)
        let diffMins = Int(diff / 60)
        let diffHours = Int(diff / 3600)
        let diffDays = Int(diff / 86_400)

        if diffMins < 1 { return L10n.chatJustNow }
        if diffMins < 60 { return L10n.chatMinsAgo(diffMins) }
        if diffHours < 24 { return L10n.chatHoursAgo(diffHours) }
        if diffDays < 7 {
            let weekday = Calendar.current.component(.weekday, from: date)
            switch weekday {
            case 2: return L10n.chatDayMon
            case 3: return L10n.chatDayTue
            case 4: return L10n.chatDayWed
            case 5: return L10n.chatDayThu
            case 6: return L10n.chatDayFri
            case 7: return L10n.chatDaySat
            default: return L10n.chatDaySun
            }
        }

        let display = DateFormatter()
        display.locale = AppLocale.locale
        display.dateFormat = "d/M"
        return display.string(from: date)
    }
}
