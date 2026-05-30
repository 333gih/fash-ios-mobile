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
                guard let itemConv = conversationId(from: item.dataMap) else { continue }
                guard itemConv.compare(cid, options: .caseInsensitive) == .orderedSame else { continue }
                _ = await userRepository.markNotificationRead(notificationId: item.id)
            }
        }
    }

    private static func conversationId(from data: [String: String]) -> String? {
        for key in ["conversation_id", "conversationId", "ConversationID"] {
            let value = data[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty { return value }
        }
        return nil
    }
}
