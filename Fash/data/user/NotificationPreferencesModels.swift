import Foundation

struct NotificationPreferences: Equatable {
    var recommendationPushEnabled: Bool
    var recommendationEmailEnabled: Bool
    var quietHoursStart: Int?
    var quietHoursEnd: Int?
}

enum NotificationPreferencesParsing {
    static func parse(_ obj: [String: Any]) -> NotificationPreferences {
        let root = (obj["data"] as? [String: Any]) ?? obj
        return NotificationPreferences(
            recommendationPushEnabled: root["recommendation_push_enabled"] as? Bool ?? true,
            recommendationEmailEnabled: root["recommendation_email_enabled"] as? Bool ?? true,
            quietHoursStart: parseHour(root["quiet_hours_start"]),
            quietHoursEnd: parseHour(root["quiet_hours_end"])
        )
    }

    private static func parseHour(_ value: Any?) -> Int? {
        switch value {
        case let n as Int where (0...23).contains(n):
            return n
        case let n as NSNumber where (0...23).contains(n.intValue):
            return n.intValue
        default:
            return nil
        }
    }

    static func toPutJSON(_ prefs: NotificationPreferences) -> [String: Any] {
        var o: [String: Any] = [
            "recommendation_push_enabled": prefs.recommendationPushEnabled,
            "recommendation_email_enabled": prefs.recommendationEmailEnabled,
        ]
        if let start = prefs.quietHoursStart {
            o["quiet_hours_start"] = start
        } else {
            o["quiet_hours_start"] = NSNull()
        }
        if let end = prefs.quietHoursEnd {
            o["quiet_hours_end"] = end
        } else {
            o["quiet_hours_end"] = NSNull()
        }
        return o
    }
}
