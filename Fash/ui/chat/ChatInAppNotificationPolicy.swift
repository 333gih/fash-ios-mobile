import Foundation

/// When to surface chat / deal in-app toasts — suppress while the user is in that conversation.
enum ChatInAppNotificationPolicy {
    static func conversationId(from data: [String: String]?) -> String? {
        guard let data else { return nil }
        for key in ["conversation_id", "conversationId", "ConversationID"] {
            let value = data[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty { return value }
        }
        return nil
    }

    static func isChatRelatedType(_ type: String?) -> Bool {
        let normalized = type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !normalized.isEmpty else { return false }
        if normalized.contains("chat") || normalized.contains("message") { return true }
        if normalized.hasPrefix("marketplace.chat.") { return true }
        if normalized.hasPrefix("meeting_") || normalized == "deal_complete_nudge" { return true }
        return false
    }

    static func isChatRelated(data: [String: String]?) -> Bool {
        if isChatRelatedType(data?["type"]) { return true }
        if isChatRelatedType(data?["event"]) { return true }
        return conversationId(from: data) != nil
    }

    static func shouldSuppressInApp(
        data: [String: String]?,
        openConversationId: String?
    ) -> Bool {
        guard let target = conversationId(from: data) else { return false }
        return isOpenConversation(target, openConversationId: openConversationId)
    }

    static func isOpenConversation(_ conversationId: String, openConversationId: String?) -> Bool {
        let target = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        let open = openConversationId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !target.isEmpty, !open.isEmpty else { return false }
        return target.compare(open, options: .caseInsensitive) == .orderedSame
    }

    static func shouldShowMessageNewInApp(
        conversationId: String,
        senderId: String,
        recipientId: String,
        messageType: String,
        systemSubtype: String?,
        myUserId: String,
        openConversationId: String?
    ) -> Bool {
        let myId = myUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !myId.isEmpty else { return false }

        let sender = senderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sender.isEmpty,
              sender.compare(myId, options: .caseInsensitive) != .orderedSame else { return false }

        let recipient = recipientId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard recipient.isEmpty || recipient.compare(myId, options: .caseInsensitive) == .orderedSame else {
            return false
        }

        if shouldSuppressInApp(
            data: ["conversation_id": conversationId],
            openConversationId: openConversationId
        ) {
            return false
        }

        let cid = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return false }

        if messageType.lowercased() == "system" {
            let sub = systemSubtype?.lowercased() ?? ""
            if sub.hasPrefix("conversation.") { return false }
        }
        return true
    }
}

struct ActiveChatSession: Equatable {
    var conversationId: String = ""
    var isFollowingBottom: Bool = true
    var newMessagesBelow: Int = 0
}
