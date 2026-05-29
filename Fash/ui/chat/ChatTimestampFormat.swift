import Foundation

enum ChatTimestampFormat {
    static func format(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        guard let date = ChatInstantParse.parse(trimmed) else {
            if let range = trimmed.range(of: #"(?<!\d)\d{2}:\d{2}(?!\d)"#, options: .regularExpression) {
                return String(trimmed[range])
            }
            return ""
        }

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
