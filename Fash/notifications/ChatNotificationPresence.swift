import Foundation

/// Side effects when chat-related in-app notifications are suppressed (user already in that thread).
@MainActor
enum ChatNotificationPresence {
    static func openConversationId(deps: AppDependencies) -> String {
        let routerId = deps.navigationRouter?.selectedConversationId?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !routerId.isEmpty { return routerId }
        return deps.activeChatSession.conversationId
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func registerOpenConversation(_ conversationId: String, deps: AppDependencies) {
        let id = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        deps.activeChatSession.conversationId = id
        if let session = deps.inAppNotification,
           ChatInAppNotificationPolicy.shouldSuppressInApp(
               data: session.dataMap,
               openConversationId: id
           ) {
            deps.dismissInAppNotification()
        }
    }

    static func clearOpenConversation(_ conversationId: String, deps: AppDependencies) {
        let id = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        if deps.activeChatSession.conversationId
            .compare(id, options: .caseInsensitive) == .orderedSame {
            deps.activeChatSession = ActiveChatSession()
        }
    }

    static func handleSuppressedChatNotification(
        data: [String: String]?,
        deps: AppDependencies
    ) {
        Task {
            if let cid = ChatInAppNotificationPolicy.conversationId(from: data) {
                await InboxNotificationSync.markChatNotificationsRead(
                    forConversationId: cid,
                    userRepository: deps.userRepository
                )
            }
            deps.requestInboxUnreadRefresh()
            if ChatInAppNotificationPolicy.isChatRelated(data: data) {
                deps.requestChatInboxRefresh()
            }
        }
    }
}
