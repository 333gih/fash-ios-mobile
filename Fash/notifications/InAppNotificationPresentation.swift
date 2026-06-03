import Foundation

/// Builds in-app banner copy — prefer peer username/display name over generic "User".
@MainActor
enum InAppNotificationPresentation {
    private static let genericActorTitles: Set<String> = [
        "user", "buyer", "người dùng", "người mua",
    ]

    static func enrich(
        _ session: FashInAppNotificationSession,
        chatVM: ChatViewModel?
    ) -> FashInAppNotificationSession {
        var title = session.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = session.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let data = session.dataMap

        if isGenericActorTitle(title),
           let resolved = resolveActorTitle(from: data, chatVM: chatVM),
           !resolved.isEmpty {
            title = resolved
        } else if title.isEmpty,
                  let resolved = resolveActorTitle(from: data, chatVM: chatVM),
                  !resolved.isEmpty {
            title = resolved
        }

        return FashInAppNotificationSession(
            title: title,
            body: body,
            userNotificationId: session.userNotificationId,
            dataMap: data
        )
    }

    /// Title for WS `message.new` in-app toast — peer name when known.
    static func chatMessageNewTitle(
        conversationId: String,
        senderId: String,
        chatVM: ChatViewModel
    ) -> String {
        if let peer = chatVM.peerLabel(forConversationId: conversationId),
           !peer.isEmpty {
            return peer
        }
        if let peer = chatVM.peerLabel(forOtherUserId: senderId),
           !peer.isEmpty {
            return peer
        }
        return L10n.notificationPtMarketplaceChatMessage
    }

    static func resolveActorTitle(
        from data: [String: String],
        chatVM: ChatViewModel?
    ) -> String? {
        for key in [
            "sender_display_name", "sender_username", "sender_name",
            "buyer_display_name", "buyer_username",
            "seller_display_name", "seller_username",
            "actor_display_name", "display_name", "username",
        ] {
            let value = data[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty, !isGenericActorTitle(value) {
                return formatHandle(value)
            }
        }
        if let cid = ChatInAppNotificationPolicy.conversationId(from: data),
           let peer = chatVM?.peerLabel(forConversationId: cid),
           !peer.isEmpty {
            return peer
        }
        return nil
    }

    private static func formatHandle(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        if trimmed.hasPrefix("@") { return trimmed }
        if trimmed.contains(" ") { return trimmed }
        return "@\(trimmed)"
    }

    static func isGenericActorTitle(_ title: String) -> Bool {
        genericActorTitles.contains(title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }
}
