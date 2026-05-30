import Foundation

/// Keeps notification inbox unread in sync when a chat thread is read in-app.
enum InboxNotificationSync {
    private static let chatGroups = ["REALTIME", "REENGAGEMENT"]

    static func markChatNotificationsRead(
        forConversationId conversationId: String,
        userRepository: UserRepository
    ) async {
        let cid = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return }

        for group in chatGroups {
            guard case .success(let page) = await userRepository.listMyNotifications(limit: 40, group: group) else {
                continue
            }
            for item in page.items where item.isUnread {
                guard let itemConv = parseConversationId(from: item.dataMap) else { continue }
                guard itemConv.compare(cid, options: .caseInsensitive) == .orderedSame else { continue }
                _ = await userRepository.markNotificationRead(notificationId: item.id)
            }
        }
    }

    private static func parseConversationId(from data: [String: Any]?) -> String? {
        guard let data else { return nil }
        for key in ["conversation_id", "conversationId", "ConversationID"] {
            let raw = data[key]
            let value: String
            if let s = raw as? String {
                value = s
            } else if let n = raw {
                value = String(describing: n)
            } else {
                continue
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}
