import Foundation

struct InboxNotificationItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let dataMap: [String: Any]?
    let payloadType: String?
    let notificationGroup: String?
    let source: String?
    let sourceEventId: String?
    let readAtIso: String?
    let createdAtIso: String

    var isUnread: Bool { (readAtIso ?? "").isEmpty }
}

struct NotificationGroupSummaryItem: Identifiable, Equatable {
    var id: String { group }
    let group: String
    let unreadCount: Int
    let latestId: String?
    let latestTitle: String?
    let latestBody: String?
    let latestCreatedAtIso: String?
}

struct InboxNotificationsPage {
    let items: [InboxNotificationItem]
}

struct InboxNotificationGroupsPage {
    let groups: [NotificationGroupSummaryItem]
}

enum InboxNotificationParser {
    static func parsePage(_ data: Data) throws -> InboxNotificationsPage {
        let root = try HttpJson.dictionary(data)
        let rows = (root["data"] as? [[String: Any]]) ?? []
        return InboxNotificationsPage(items: rows.compactMap(parseItem))
    }

    static func parseGroupsPage(_ data: Data) throws -> InboxNotificationGroupsPage {
        let root = try HttpJson.dictionary(data)
        let rows = (root["data"] as? [[String: Any]]) ?? []
        let groups = rows.compactMap { row -> NotificationGroupSummaryItem? in
            guard let group = (row["group"] as? String)?.trimmingCharacters(in: .whitespaces), !group.isEmpty else { return nil }
            return NotificationGroupSummaryItem(
                group: group,
                unreadCount: max(0, (row["unread_count"] as? NSNumber)?.intValue ?? 0),
                latestId: row["latest_id"] as? String,
                latestTitle: row["latest_title"] as? String,
                latestBody: row["latest_body"] as? String,
                latestCreatedAtIso: row["latest_created_at"] as? String
            )
        }
        return InboxNotificationGroupsPage(groups: groups)
    }

    static func parseItem(_ row: [String: Any]) -> InboxNotificationItem? {
        guard let id = (row["id"] as? String)?.trimmingCharacters(in: .whitespaces), !id.isEmpty else { return nil }
        return InboxNotificationItem(
            id: id,
            title: row["title"] as? String ?? "",
            body: row["body"] as? String ?? "",
            dataMap: row["data"] as? [String: Any],
            payloadType: row["payload_type"] as? String,
            notificationGroup: row["notification_group"] as? String,
            source: row["source"] as? String,
            sourceEventId: row["source_event_id"] as? String,
            readAtIso: row["read_at"] as? String,
            createdAtIso: row["created_at"] as? String ?? ""
        )
    }
}
