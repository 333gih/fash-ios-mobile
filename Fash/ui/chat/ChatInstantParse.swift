import Foundation

/// RFC3339 / GORM / core-service timestamps — Android `parseChatInstant` + `Instant.parse`.
enum ChatInstantParse {
    static func parse(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = normalize(trimmed)

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: normalized) { return date }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let date = plain.date(from: normalized) { return date }

        let posix = DateFormatter()
        posix.locale = Locale(identifier: "en_US_POSIX")
        posix.timeZone = TimeZone(secondsFromGMT: 0)
        for pattern in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss",
        ] {
            posix.dateFormat = pattern
            if let date = posix.date(from: normalized) { return date }
        }
        return nil
    }

    /// Bubble clock label — Android [ChatDetailViewModel.formatTime] (`HH:mm`, local zone).
    static func formatClockTime(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if let date = parse(trimmed) {
            let fmt = DateFormatter()
            fmt.locale = AppLocale.locale
            fmt.timeZone = .current
            fmt.dateFormat = "HH:mm"
            return fmt.string(from: date)
        }

        if let range = trimmed.range(of: #"(?<!\d)\d{2}:\d{2}(?!\d)"#, options: .regularExpression) {
            return String(trimmed[range])
        }
        return ""
    }

    private static func normalize(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.contains("T") {
            if let space = s.firstIndex(of: " ") {
                s.replaceSubrange(space...space, with: "T")
            } else if s.count == 10 {
                return "\(s)T00:00:00Z"
            }
        }

        s = truncateFractionalSeconds(s)
        s = normalizeTimezoneOffset(s)

        if needsUtcSuffix(s) {
            s += "Z"
        }
        return s
    }

    /// ISO8601DateFormatter accepts at most 3 fractional digits; GORM may emit nanoseconds.
    private static func truncateFractionalSeconds(_ value: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "(\\.\\d{1,3})\\d+") else { return value }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, range: range, withTemplate: "$1")
    }

    /// `+0700` → `+07:00` for Foundation parsers.
    private static func normalizeTimezoneOffset(_ value: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "([+-])(\\d{2})(\\d{2})$") else { return value }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, range: range, withTemplate: "$1$2:$3")
    }

    private static func needsUtcSuffix(_ value: String) -> Bool {
        guard let tIndex = value.firstIndex(of: "T") else { return false }
        let suffix = value[value.index(after: tIndex)...]
        if suffix.hasSuffix("Z") || suffix.hasSuffix("z") { return false }
        if suffix.range(of: #"[+-]\d{2}:\d{2}$"#, options: .regularExpression) != nil { return false }
        if suffix.range(of: #"[+-]\d{4}$"#, options: .regularExpression) != nil { return false }
        return suffix.range(of: #"\d{2}:\d{2}"#, options: .regularExpression) != nil
    }
}
