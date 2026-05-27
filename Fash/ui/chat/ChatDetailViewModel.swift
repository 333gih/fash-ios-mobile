import Foundation
import Observation

@Observable
@MainActor
final class ChatDetailViewModel {
    var detail: ConversationDetail?
    var messages: [ChatMessage] = []
    var inputText = ""
    var isLoading = false
    var isMessagesLoading = false
    var isSending = false
    var loadError: String?

    private var pollTask: Task<Void, Never>?
    private var loadedConversationId: String?

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func load(conversationId: String, deps: AppDependencies) async {
        guard !conversationId.isEmpty else {
            loadError = L10n.chatLoadError
            return
        }
        if loadedConversationId != conversationId {
            pollTask?.cancel()
            detail = nil
            messages = []
            inputText = ""
        }
        loadedConversationId = conversationId
        isLoading = detail == nil
        loadError = nil
        defer { isLoading = false }

        async let detailResult = deps.chatRepository.getConversationDetail(conversationId: conversationId)
        async let messagesResult = deps.chatRepository.getMessages(conversationId: conversationId)

        switch await detailResult {
        case .success(let d):
            detail = d
        case .failure(let error):
            loadError = error.localizedDescription
        }

        isMessagesLoading = true
        switch await messagesResult {
        case .success(let msgs):
            messages = msgs.sorted { $0.timestamp < $1.timestamp }
        case .failure(let error):
            if loadError == nil { loadError = error.localizedDescription }
        }
        isMessagesLoading = false

        _ = await deps.chatRepository.markConversationRead(conversationId: conversationId)
        startPolling(conversationId: conversationId, deps: deps)
    }

    func onInputChange(_ text: String) {
        guard !(detail?.isClosed ?? false) else { return }
        inputText = text
    }

    func sendMessage(deps: AppDependencies) async {
        guard !(detail?.isClosed ?? false) else { return }
        let convId = detail?.conversationId ?? loadedConversationId ?? ""
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !convId.isEmpty, !text.isEmpty, !isSending else { return }

        let tempId = "local-\(UUID().uuidString)"
        let myId = deps.authSessionStore.read()?.userId ?? ""
        let optimistic = ChatMessage(
            messageId: tempId,
            text: text,
            isFromMe: true,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            isRead: false,
            senderId: myId,
            messageType: "text",
            offerAmountVnd: 0,
            offerStatus: "",
            outboundState: .sending,
            systemSubtype: nil
        )
        isSending = true
        inputText = ""
        messages.append(optimistic)

        let result = await deps.chatRepository.sendMessage(conversationId: convId, text: text)
        isSending = false
        switch result {
        case .success(let msg):
            messages.removeAll { $0.messageId == tempId }
            if !messages.contains(where: { $0.messageId == msg.messageId }) {
                messages.append(msg)
            }
            messages.sort { $0.timestamp < $1.timestamp }
        case .failure(let error):
            messages = messages.map { row in
                row.messageId == tempId ? ChatMessage(
                    messageId: row.messageId,
                    text: row.text,
                    isFromMe: row.isFromMe,
                    timestamp: row.timestamp,
                    isRead: row.isRead,
                    senderId: row.senderId,
                    messageType: row.messageType,
                    offerAmountVnd: row.offerAmountVnd,
                    offerStatus: row.offerStatus,
                    outboundState: .failed,
                    systemSubtype: row.systemSubtype
                ) : row
            }
            inputText = text
            loadError = error.localizedDescription
        }
    }

    private func startPolling(conversationId: String, deps: AppDependencies) {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                async let detailResult = deps.chatRepository.getConversationDetail(conversationId: conversationId)
                async let messagesResult = deps.chatRepository.getMessages(conversationId: conversationId)
                if case .success(let d) = await detailResult { detail = d }
                if case .success(let msgs) = await messagesResult {
                    let pending = messages.filter { $0.messageId.hasPrefix("local-") }
                    var merged = msgs
                    for p in pending {
                        let superseded = msgs.contains { $0.isFromMe && $0.messageType == "text" && $0.text == p.text }
                        if !superseded { merged.append(p) }
                    }
                    messages = merged.sorted { $0.timestamp < $1.timestamp }
                }
            }
        }
    }

    func formatTime(_ timestamp: String) -> String {
        guard !timestamp.isEmpty else { return "" }
        let normalized = timestamp.contains("T") ? timestamp : timestamp.replacingOccurrences(of: " ", with: "T")
        if let date = ISO8601DateFormatter().date(from: normalized) {
            let fmt = DateFormatter()
            fmt.timeStyle = .short
            return fmt.string(from: date)
        }
        return String(timestamp.prefix(5))
    }
}
