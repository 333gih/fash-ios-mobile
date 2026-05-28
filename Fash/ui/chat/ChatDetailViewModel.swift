import Foundation
import Observation

private let pollIntervalSec: TimeInterval = 5
private let silentRefreshDebounceMs: UInt64 = 400_000_000

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
    var eventMessage: String?

    var isRespondingToOffer = false
    var isCreatingOffer = false
    var isCreatingCounterOffer = false
    var showOfferSheet = false
    var counterOfferSheet: CounterOfferSheetArgs?

    var orderId: String?
    var orderStatus: String?
    var orderAmountVnd: Int64 = 0
    var orderRemainingSeconds: Int64 = 0
    var orderExpiryKind: String = ""
    var orderMeetupDeadlineAt: String?

    private var pollTask: Task<Void, Never>?
    private var realtimeListenerId: UUID?
    private var silentRefreshTask: Task<Void, Never>?
    private var orderPollTask: Task<Void, Never>?
    private var loadedConversationId: String?

    var hasOrder: Bool { orderId?.isEmpty == false || detail?.hasOrder == true }
    var maxOffers: Int { BusinessFlowConfig.maxOffersPerConversation }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
        if let id = realtimeListenerId {
            AppDependencies.shared.realtimeManager.removeEventListener(id)
            realtimeListenerId = nil
        }
        silentRefreshTask?.cancel()
        silentRefreshTask = nil
        orderPollTask?.cancel()
        orderPollTask = nil
        if let id = loadedConversationId {
            AppDependencies.shared.realtimeManager.unsubscribeFromConversation(id)
        }
    }

    func load(conversationId: String, deps: AppDependencies) async {
        guard !conversationId.isEmpty else {
            loadError = L10n.chatLoadError
            return
        }
        if loadedConversationId != conversationId {
            stopPolling()
            detail = nil
            messages = []
            inputText = ""
            orderId = nil
            orderStatus = nil
        }
        loadedConversationId = conversationId
        isLoading = detail == nil
        loadError = nil
        defer { isLoading = false }

        await refreshAll(conversationId: conversationId, deps: deps)
        _ = await deps.chatRepository.markConversationRead(conversationId: conversationId)
        startPolling(conversationId: conversationId, deps: deps)
        bindRealtime(conversationId: conversationId, deps: deps)
        deps.realtimeManager.subscribeToConversation(conversationId)
    }

    func sendMessage(deps: AppDependencies) async {
        guard detail?.isClosed != true, detail?.product?.isSold != true else { return }
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
            systemSubtype: nil,
            meetingAppointment: nil
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
                guard row.messageId == tempId else { return row }
                return ChatMessage(
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
                    systemSubtype: row.systemSubtype,
                    meetingAppointment: row.meetingAppointment
                )
            }
            inputText = text
            eventMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    // MARK: - Offers

    func canShowOfferButton(deps: AppDependencies) -> Bool {
        guard let d = detail, d.isBuyer else { return false }
        guard !d.isClosed, d.product?.isSold != true else { return false }
        guard !hasOrder else { return false }
        guard d.pendingOffer == nil else { return false }
        guard d.offerCount < maxOffers else { return false }
        return true
    }

    func createOffer(amountVnd: Int64, deps: AppDependencies) async {
        guard let d = detail else { return }
        if d.pendingOffer != nil {
            eventMessage = L10n.chatErrorPendingOffer
            return
        }
        if hasOrder {
            eventMessage = L10n.chatErrorOrderExists
            return
        }
        if d.offerCount >= maxOffers {
            eventMessage = L10n.chatErrorOfferLimit(maxOffers)
            return
        }
        showOfferSheet = false
        isCreatingOffer = true
        defer { isCreatingOffer = false }
        let result = await deps.chatRepository.createOffer(conversationId: d.conversationId, amountVnd: amountVnd)
        switch result {
        case .success(let offer):
            detail = ConversationDetail(
                conversationId: d.conversationId,
                otherUser: d.otherUser,
                product: d.product,
                isBuyer: d.isBuyer,
                orderId: d.orderId,
                offerCount: d.offerCount + 1,
                isClosed: d.isClosed,
                pendingOffer: PriceOffer(
                    offerId: offer.offerId,
                    amountVnd: offer.amountVnd,
                    status: offer.status,
                    proposedByMe: true
                ),
                myReport: d.myReport
            )
            await refreshMessages(conversationId: d.conversationId, deps: deps)
        case .failure(let error):
            eventMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func submitCounterOffer(amountVnd: Int64, deps: AppDependencies) async {
        guard let args = counterOfferSheet, let d = detail else { return }
        guard amountVnd >= 1000 else {
            eventMessage = L10n.chatCounterOfferMin
            return
        }
        isCreatingCounterOffer = true
        defer { isCreatingCounterOffer = false }
        let result = await deps.chatRepository.createCounterOffer(
            conversationId: d.conversationId,
            buyerOfferMessageId: args.buyerOfferMessageId,
            amountVnd: amountVnd
        )
        switch result {
        case .success(let msg):
            counterOfferSheet = nil
            detail = ConversationDetail(
                conversationId: d.conversationId,
                otherUser: d.otherUser,
                product: d.product,
                isBuyer: d.isBuyer,
                orderId: d.orderId,
                offerCount: d.offerCount + 1,
                isClosed: d.isClosed,
                pendingOffer: PriceOffer(
                    offerId: msg.messageId,
                    amountVnd: msg.offerAmountVnd,
                    status: "pending",
                    proposedByMe: true
                ),
                myReport: d.myReport
            )
            await refreshMessages(conversationId: d.conversationId, deps: deps)
            if case .success(let fresh) = await deps.chatRepository.getConversationDetail(conversationId: d.conversationId) {
                detail = detail.map { $0.withOfferCount(fresh.offerCount) }
            }
        case .failure(let error):
            eventMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func acceptOffer(_ message: ChatMessage, deps: AppDependencies) async {
        guard let d = detail else { return }
        isRespondingToOffer = true
        defer { isRespondingToOffer = false }
        let result = await deps.chatRepository.acceptOfferUnified(
            conversationId: d.conversationId,
            offerMessageId: message.messageId
        )
        switch result {
        case .success(let orderIdHint):
            detail = d.withPendingOffer(nil)
            eventMessage = L10n.chatOfferAccepted
            await refreshAll(conversationId: d.conversationId, deps: deps)
            if let oid = orderIdHint?.trimmingCharacters(in: .whitespacesAndNewlines), !oid.isEmpty {
                orderId = oid
                detail = detail?.withOrderId(oid)
                await fetchOrder(orderId: oid, deps: deps)
            }
        case .failure(let error):
            eventMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func declineOffer(_ message: ChatMessage, deps: AppDependencies) async {
        guard let d = detail else { return }
        isRespondingToOffer = true
        defer { isRespondingToOffer = false }
        let result = await deps.chatRepository.respondToOffer(
            conversationId: d.conversationId,
            offerMessageId: message.messageId,
            accept: false
        )
        switch result {
        case .success:
            detail = d.withPendingOffer(nil)
            await refreshMessages(conversationId: d.conversationId, deps: deps)
        case .failure(let error):
            eventMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func agreedAmountVnd() -> Int64 {
        if orderAmountVnd >= 1000 { return orderAmountVnd }
        return messages.last(where: { $0.offerStatus == "accepted" && $0.offerAmountVnd >= 1000 })?.offerAmountVnd ?? 0
    }

    // MARK: - Refresh

    private func refreshAll(conversationId: String, deps: AppDependencies) async {
        async let detailResult = deps.chatRepository.getConversationDetail(conversationId: conversationId)
        async let messagesResult = deps.chatRepository.getMessages(conversationId: conversationId)
        if case .success(let d) = await detailResult {
            detail = d
            if let oid = d.orderId, !oid.isEmpty {
                orderId = oid
                await fetchOrder(orderId: oid, deps: deps)
            }
        } else if case .failure(let error) = await detailResult {
            loadError = FashErrorPresentation.userMessage(for: error)
        }
        isMessagesLoading = true
        if case .success(let msgs) = await messagesResult {
            messages = mergeWithPendingLocal(msgs)
        } else if case .failure(let error) = await messagesResult, loadError == nil {
            loadError = FashErrorPresentation.userMessage(for: error)
        }
        isMessagesLoading = false
    }

    private func refreshMessages(conversationId: String, deps: AppDependencies) async {
        if case .success(let msgs) = await deps.chatRepository.getMessages(conversationId: conversationId) {
            messages = mergeWithPendingLocal(msgs)
        }
        isCreatingOffer = false
        isCreatingCounterOffer = false
    }

    private func mergeWithPendingLocal(_ server: [ChatMessage]) -> [ChatMessage] {
        let pending = messages.filter { $0.messageId.hasPrefix("local-") }
        var merged = server
        for p in pending {
            let superseded = server.contains { $0.isFromMe && $0.messageType == "text" && $0.text == p.text }
            if !superseded { merged.append(p) }
        }
        return merged.sorted { $0.timestamp < $1.timestamp }
    }

    private func fetchOrder(orderId: String, deps: AppDependencies) async {
        guard case .success(let payload) = await deps.orderRepository.getOrderDetail(orderId: orderId) else { return }
        orderStatus = payload.status
        orderAmountVnd = payload.amountVnd > 0 ? payload.amountVnd : payload.listingPriceVnd
        orderRemainingSeconds = payload.remainingSeconds
        orderExpiryKind = payload.expiryKind
        orderMeetupDeadlineAt = payload.meetupDeadlineAt
    }

    private func scheduleSilentRefresh(conversationId: String, deps: AppDependencies) {
        silentRefreshTask?.cancel()
        silentRefreshTask = Task {
            try? await Task.sleep(nanoseconds: silentRefreshDebounceMs)
            guard !Task.isCancelled else { return }
            await refreshAll(conversationId: conversationId, deps: deps)
        }
    }

    private func startPolling(conversationId: String, deps: AppDependencies) {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(pollIntervalSec))
                guard !Task.isCancelled else { break }
                await refreshAll(conversationId: conversationId, deps: deps)
            }
        }
    }

    private func bindRealtime(conversationId: String, deps: AppDependencies) {
        if let id = realtimeListenerId {
            deps.realtimeManager.removeEventListener(id)
        }
        realtimeListenerId = deps.realtimeManager.addEventListener { [weak self] event in
            guard let self else { return }
            switch event {
            case .messageNew(let cid, _, _, _, _, _, _),
                 .readReceipts(let cid, _, _),
                 .offerLimitReset(_, let cid, _),
                 .conversationClosed(let cid),
                 .conversationReopened(let cid):
                guard cid == conversationId || cid.isEmpty else { return }
                scheduleSilentRefresh(conversationId: conversationId, deps: deps)
            case .orderStatusChanged(let oid, let cid, let status):
                if cid == conversationId || cid.isEmpty {
                    scheduleSilentRefresh(conversationId: conversationId, deps: deps)
                }
                if oid == self.orderId || (!oid.isEmpty && self.orderId == nil) {
                    self.orderStatus = status
                    Task { await self.fetchOrder(orderId: oid.isEmpty ? (self.orderId ?? "") : oid, deps: deps) }
                }
            case .listingSold, .listingReserved, .listingAvailable:
                scheduleSilentRefresh(conversationId: conversationId, deps: deps)
            default:
                break
            }
        }
    }

    func formatTime(_ timestamp: String) -> String {
        guard !timestamp.isEmpty else { return "" }
        let normalized = timestamp.contains("T") ? timestamp : timestamp.replacingOccurrences(of: " ", with: "T")
        if let date = ISO8601DateFormatter().date(from: normalized) {
            let fmt = DateFormatter()
            fmt.locale = AppLocale.locale
            fmt.timeStyle = .short
            return fmt.string(from: date)
        }
        return String(timestamp.prefix(5))
    }
}

private extension ConversationDetail {
    func withPendingOffer(_ offer: PriceOffer?) -> ConversationDetail {
        ConversationDetail(
            conversationId: conversationId,
            otherUser: otherUser,
            product: product,
            isBuyer: isBuyer,
            orderId: orderId,
            offerCount: offerCount,
            isClosed: isClosed,
            pendingOffer: offer,
            myReport: myReport
        )
    }

    func withOrderId(_ id: String) -> ConversationDetail {
        ConversationDetail(
            conversationId: conversationId,
            otherUser: otherUser,
            product: product,
            isBuyer: isBuyer,
            orderId: id,
            offerCount: offerCount,
            isClosed: isClosed,
            pendingOffer: pendingOffer,
            myReport: myReport
        )
    }

    func withOfferCount(_ count: Int) -> ConversationDetail {
        ConversationDetail(
            conversationId: conversationId,
            otherUser: otherUser,
            product: product,
            isBuyer: isBuyer,
            orderId: orderId,
            offerCount: count,
            isClosed: isClosed,
            pendingOffer: pendingOffer,
            myReport: myReport
        )
    }
}
