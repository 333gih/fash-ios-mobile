import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {
    var conversations: [ConversationItem] = []
    var isLoading = false
    var isRefreshing = false
    var loadError = false
    var unreadTotal = 0

    var conversationIds: [String] { conversations.map(\.conversationId) }

    func refresh(deps: AppDependencies) async {
        isLoading = true
        loadError = false
        defer { isLoading = false }
        async let inbox = deps.chatRepository.getConversations()
        async let unread = deps.chatRepository.getUnreadCount()
        let inboxResult = await inbox
        let unreadResult = await unread
        switch inboxResult {
        case .success(let list):
            conversations = list
            loadError = false
        case .failure:
            conversations = []
            loadError = true
        }
        if case .success(let count) = unreadResult {
            unreadTotal = count
        }
    }

    func pullToRefresh(deps: AppDependencies) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(deps: deps)
    }

    func silentRefresh(deps: AppDependencies) async {
        async let inbox = deps.chatRepository.getConversations()
        async let unread = deps.chatRepository.getUnreadCount()
        let inboxResult = await inbox
        let unreadResult = await unread
        if case .success(let list) = inboxResult {
            conversations = list
            loadError = false
        }
        if case .success(let count) = unreadResult {
            unreadTotal = count
        }
    }

    func resyncConversationSubscriptions(deps: AppDependencies) async {
        for id in conversations.prefix(50).map(\.conversationId) {
            deps.realtimeManager.subscribeToConversation(id)
        }
    }
}
