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
    var offerFormError: String?
    var counterFormError: String?

    var orderId: String?
    var orderStatus: String?
    var orderAmountVnd: Int64 = 0
    var orderRemainingSeconds: Int64 = 0
    var orderExpiryKind: String = ""
    var orderMeetupDeadlineAt: String?
    var orderMeetingAppointmentStatus = ""
    var orderMeetingScheduledAt = ""
    var orderMeetupBothPartiesCheckedIn = false

    var meetingBrowseProvinceId: String?
    var meetingBrowseDistrictId: String?
    var isProposingMeeting = false
    var meetingMutationInFlight = false
    var showMeetingIdentityReverify = false
    var ackMeetingReverifyInFlight = false

    /// True while the other participant is typing (Android `isOtherTyping`).
    var isOtherTyping = false

    private var pollTask: Task<Void, Never>?
    private var realtimeListenerId: UUID?
    private var silentRefreshTask: Task<Void, Never>?
    private var orderPollTask: Task<Void, Never>?
    private var typingTimeoutTask: Task<Void, Never>?
    private var loadedConversationId: String?

    var hasOrder: Bool { orderId?.isEmpty == false || detail?.hasOrder == true }
    var maxOffers: Int { BusinessFlowConfig.maxOffersPerConversation }

    var shouldHideScheduleMeetup: Bool {
        ChatMeetupSchedulingPolicy.dealBannerShouldHideScheduleMeetup(
            orderStatus: orderStatus,
            orderApptStatus: orderMeetingAppointmentStatus,
            messages: messages
        )
    }

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
        typingTimeoutTask?.cancel()
        typingTimeoutTask = nil
        isOtherTyping = false
        if let id = loadedConversationId {
            AppDependencies.shared.realtimeManager.sendTypingStop(conversationId: id)
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
            isOtherTyping = false
        }
        loadedConversationId = conversationId
        isLoading = detail == nil
        loadError = nil
        defer { isLoading = false }

        await refreshAll(conversationId: conversationId, deps: deps)
        if case .success = await deps.chatRepository.markConversationRead(conversationId: conversationId) {
            ChatUnreadRefreshHub.notifyMarkedRead()
        }
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
            meetingAppointment: nil,
            orderCancelled: nil
        )
        isSending = true
        inputText = ""
        deps.realtimeManager.sendTypingStop(conversationId: convId)
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
                    meetingAppointment: row.meetingAppointment,
                    orderCancelled: row.orderCancelled
                )
            }
            inputText = text
            eventMessage = ChatErrorPresentation.mapSendMessageError(error)
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
        offerFormError = nil
        if d.pendingOffer != nil {
            eventMessage = L10n.chatErrorPendingOffer
            return
        }
        if hasOrder {
            eventMessage = L10n.chatErrorOrderExists
            return
        }
        if ChatMeetupSchedulingPolicy.shouldBlockBuyerNewPriceOffer(
            messages: messages,
            viewerIsBuyer: d.isBuyer,
            orderStatus: orderStatus,
            orderApptStatus: orderMeetingAppointmentStatus,
            orderApptScheduledAt: orderMeetingScheduledAt
        ) {
            eventMessage = L10n.chatOfferBlockedActiveMeetup
            return
        }
        if d.offerCount >= maxOffers {
            eventMessage = L10n.chatErrorOfferLimit(maxOffers)
            return
        }
        let listed = d.product?.priceVnd ?? 0
        if let validation = ChatErrorPresentation.validateBuyerOffer(amountVnd: amountVnd, listedPriceVnd: listed) {
            offerFormError = validation
            return
        }
        isCreatingOffer = true
        defer { isCreatingOffer = false }
        let result = await deps.chatRepository.createOffer(conversationId: d.conversationId, amountVnd: amountVnd)
        switch result {
        case .success(let offer):
            showOfferSheet = false
            offerFormError = nil
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
            let msg = ChatErrorPresentation.mapOfferError(error, listedPriceVnd: listed)
            offerFormError = msg
            eventMessage = msg
        }
    }

    func submitCounterOffer(amountVnd: Int64, deps: AppDependencies) async {
        guard let args = counterOfferSheet, let d = detail else { return }
        counterFormError = nil
        if d.isBuyer {
            eventMessage = L10n.chatOfferError
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
        let listed = d.product?.priceVnd ?? 0
        if let validation = ChatErrorPresentation.validateCounterOffer(
            amountVnd: amountVnd,
            buyerOfferVnd: args.buyerOfferAmountVnd,
            listedPriceVnd: listed
        ) {
            counterFormError = validation
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
            counterFormError = nil
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
            let msg = ChatErrorPresentation.mapOfferError(error, listedPriceVnd: listed)
            counterFormError = msg
            eventMessage = msg
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
            eventMessage = ChatErrorPresentation.mapOfferActionError(error)
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
            eventMessage = ChatErrorPresentation.mapOfferActionError(error)
        }
    }

    func agreedAmountVnd() -> Int64 {
        if orderAmountVnd >= 1000 { return orderAmountVnd }
        return messages.last(where: { $0.offerStatus == "accepted" && $0.offerAmountVnd >= 1000 })?.offerAmountVnd ?? 0
    }

    // MARK: - Fulfillment & meetup

    func loadMeetingBrowseLocation(deps: AppDependencies) async {
        _ = deps
        meetingBrowseProvinceId = nil
        meetingBrowseDistrictId = nil
    }

    func ensureFulfillmentCashMeetup(deps: AppDependencies) async -> Bool {
        await ensureFulfillmentChosen(channel: "cash_meetup", deps: deps)
    }

    private func ensureFulfillmentChosen(channel: String, deps: AppDependencies) async -> Bool {
        guard let oid = orderId?.trimmingCharacters(in: .whitespacesAndNewlines), !oid.isEmpty else { return false }
        let st = orderStatus?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if st != "fulfillment_pending" { return true }
        switch await deps.orderRepository.chooseOrderFulfillment(orderId: oid, fulfillment: channel) {
        case .success:
            await fetchOrder(orderId: oid, deps: deps)
            return true
        case .failure(let err):
            eventMessage = FashErrorPresentation.userMessage(for: err).isEmpty ? L10n.chatFulfillmentChooseFailed : FashErrorPresentation.userMessage(for: err)
            return false
        }
    }

    func proposeMeeting(
        conversationId: String,
        locationUrl: String,
        scheduledAtIso: String,
        reminderEnabled: Bool,
        reminderOffsetMinutes: Int,
        safeZoneId: String?,
        safeZoneName: String?,
        deps: AppDependencies
    ) async -> Bool {
        let convId = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !convId.isEmpty else {
            eventMessage = L10n.chatMeetingError
            return false
        }
        let hasZone = !(safeZoneId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if !hasZone, !ChatMapsUrlRules.isLenientMeetingMapsUrl(locationUrl) {
            eventMessage = L10n.chatMeetingMapsUrlInvalid
            return false
        }
        isProposingMeeting = true
        defer { isProposingMeeting = false }
        switch await deps.chatRepository.proposeMeeting(
            conversationId: convId,
            locationUrl: locationUrl,
            scheduledAtRfc3339: scheduledAtIso,
            reminderEnabled: reminderEnabled,
            reminderOffsetMinutes: reminderOffsetMinutes,
            safeZoneId: safeZoneId,
            safeZoneName: safeZoneName
        ) {
        case .success:
            eventMessage = L10n.chatMeetingProposedOk
            await refreshMessages(conversationId: convId, deps: deps)
            if let oid = orderId, !oid.isEmpty { await fetchOrder(orderId: oid, deps: deps) }
            return true
        case .failure(let err):
            let msg = FashErrorPresentation.userMessage(for: err)
            if MeetingTrustErrorCodes.isIdentityReverifyRequired(msg) {
                showMeetingIdentityReverify = true
            } else {
                eventMessage = msg
            }
            return false
        }
    }

    func confirmMeeting(appointmentId: String, deps: AppDependencies) async {
        guard let convId = detail?.conversationId else { return }
        meetingMutationInFlight = true
        defer { meetingMutationInFlight = false }
        switch await deps.chatRepository.confirmMeeting(appointmentId: appointmentId) {
        case .success:
            eventMessage = L10n.chatMeetingConfirmedOk
            await refreshMessages(conversationId: convId, deps: deps)
            if let oid = orderId, !oid.isEmpty { await fetchOrder(orderId: oid, deps: deps) }
        case .failure(let err):
            eventMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    func cancelMeeting(appointmentId: String, deps: AppDependencies) async {
        guard let convId = detail?.conversationId else { return }
        meetingMutationInFlight = true
        defer { meetingMutationInFlight = false }
        switch await deps.chatRepository.cancelMeeting(appointmentId: appointmentId) {
        case .success(let meta):
            eventMessage = L10n.chatMeetingCancelledOk
            await refreshMessages(conversationId: convId, deps: deps)
            if let oid = orderId, !oid.isEmpty { await fetchOrder(orderId: oid, deps: deps) }
            if meta.suggestSellerReopenListing, detail?.isBuyer == false {
                eventMessage = L10n.chatMeetingCancelSuggestReopen
            }
        case .failure(let err):
            eventMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    func onMyWayMeeting(appointmentId: String, deps: AppDependencies) async {
        guard let convId = detail?.conversationId else { return }
        meetingMutationInFlight = true
        defer { meetingMutationInFlight = false }
        switch await deps.chatRepository.meetingOnMyWay(appointmentId: appointmentId) {
        case .success:
            eventMessage = L10n.meetingOnMyWayOk
            await refreshMessages(conversationId: convId, deps: deps)
        case .failure(let err):
            eventMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    func checkInMeeting(appointmentId: String, deps: AppDependencies) async {
        guard let convId = detail?.conversationId else { return }
        meetingMutationInFlight = true
        defer { meetingMutationInFlight = false }
        switch await deps.chatRepository.checkInMeeting(appointmentId: appointmentId) {
        case .success(let r):
            if !r.endpointAvailable {
                eventMessage = L10n.chatMeetingCheckInRefreshOnly
            } else if r.alreadyCheckedIn {
                eventMessage = L10n.chatMeetingCheckInAlready
            } else {
                eventMessage = L10n.chatMeetingCheckInOk
            }
            await refreshMessages(conversationId: convId, deps: deps)
            if let oid = orderId, !oid.isEmpty { await fetchOrder(orderId: oid, deps: deps) }
        case .failure(let err):
            eventMessage = ChatErrorPresentation.mapMeetingCheckInError(err)
        }
    }

    func ackMeetingIdentityReverify(deps: AppDependencies) async {
        guard !ackMeetingReverifyInFlight else { return }
        ackMeetingReverifyInFlight = true
        defer { ackMeetingReverifyInFlight = false }
        switch await deps.userRepository.ackMeetingIdentityReverify() {
        case .success:
            showMeetingIdentityReverify = false
            eventMessage = L10n.meetingIdentityReverifyAckOk
        case .failure(let err):
            eventMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    // MARK: - Typing

    private var isComposerReadOnly: Bool {
        detail?.isClosed == true || detail?.product?.isSold == true
    }

    /// Outbound typing — Android `onInputChange`.
    func onInputChange(deps: AppDependencies) {
        guard !isComposerReadOnly else { return }
        let convId = detail?.conversationId ?? loadedConversationId ?? ""
        guard !convId.isEmpty else { return }
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deps.realtimeManager.sendTypingStop(conversationId: convId)
        } else {
            deps.realtimeManager.sendTypingStart(conversationId: convId)
        }
    }

    private func scheduleTypingTimeout() {
        typingTimeoutTask?.cancel()
        typingTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            isOtherTyping = false
        }
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
        orderMeetingAppointmentStatus = payload.meetingAppointment?.status ?? ""
        orderMeetingScheduledAt = payload.meetingAppointment?.scheduledAt ?? ""
        orderMeetupBothPartiesCheckedIn = payload.meetingGrace?.sosUnlocked == true
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
            case .connected:
                deps.realtimeManager.subscribeToConversation(conversationId)
            case .typingStart(let cid, let userId):
                guard sameConversation(eventConvId: cid, openConvId: conversationId) else { return }
                let myId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let other = userId.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !other.isEmpty, other.compare(myId, options: .caseInsensitive) != .orderedSame else { return }
                isOtherTyping = true
                scheduleTypingTimeout()
            case .typingStop(let cid, let userId):
                guard sameConversation(eventConvId: cid, openConvId: conversationId) else { return }
                let myId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
                if uid.isEmpty || uid.compare(myId, options: .caseInsensitive) == .orderedSame { return }
                isOtherTyping = false
                typingTimeoutTask?.cancel()
            case .messageNew(
                let cid,
                _,
                let senderId,
                let recipientId,
                _,
                _,
                let systemSubtype
            ):
                if sameConversation(eventConvId: cid, openConvId: conversationId) {
                    if systemSubtype?.compare("conversation.closed", options: .caseInsensitive) == .orderedSame {
                        applyConversationClosedFromRealtime(conversationId: conversationId, deps: deps)
                    } else if systemSubtype?.compare("conversation.reopened", options: .caseInsensitive) == .orderedSame {
                        applyConversationReopenedFromRealtime(conversationId: conversationId)
                    } else {
                        scheduleSilentRefresh(conversationId: conversationId, deps: deps)
                    }
                } else if messageNewShouldRefreshChat(
                    eventConversationId: cid,
                    senderId: senderId,
                    recipientId: recipientId,
                    openConversationId: conversationId,
                    deps: deps
                ) {
                    scheduleSilentRefresh(conversationId: conversationId, deps: deps)
                }
            case .readReceipts(let cid, _, _):
                guard sameConversation(eventConvId: cid, openConvId: conversationId) else { return }
                scheduleSilentRefresh(conversationId: conversationId, deps: deps)
            case .offerLimitReset(_, let cid, let newPriceVnd):
                guard sameConversation(eventConvId: cid, openConvId: conversationId), let d = detail else { return }
                detail = ConversationDetail(
                    conversationId: d.conversationId,
                    otherUser: d.otherUser,
                    product: d.product.map { p in
                        ChatProductCard(
                            listingId: p.listingId,
                            title: p.title,
                            priceVnd: newPriceVnd > 0 ? newPriceVnd : p.priceVnd,
                            imageUrl: p.imageUrl,
                            listingStatus: p.listingStatus
                        )
                    },
                    isBuyer: d.isBuyer,
                    orderId: d.orderId,
                    offerCount: 0,
                    isClosed: d.isClosed,
                    pendingOffer: d.pendingOffer,
                    myReport: d.myReport
                )
                eventMessage = L10n.chatOfferLimitResetBanner(FeedPriceFormat.format(newPriceVnd))
            case .conversationClosed(let cid):
                guard sameConversation(eventConvId: cid, openConvId: conversationId) else { return }
                applyConversationClosedFromRealtime(conversationId: conversationId, deps: deps)
            case .conversationReopened(let cid):
                guard sameConversation(eventConvId: cid, openConvId: conversationId) else { return }
                applyConversationReopenedFromRealtime(conversationId: conversationId)
            case .orderStatusChanged(let oid, let cid, let status):
                if sameConversation(eventConvId: cid, openConvId: conversationId) {
                    scheduleSilentRefresh(conversationId: conversationId, deps: deps)
                }
                if oid == self.orderId || (!oid.isEmpty && self.orderId == nil) {
                    self.orderStatus = status
                    Task { await self.fetchOrder(orderId: oid.isEmpty ? (self.orderId ?? "") : oid, deps: deps) }
                }
            case .listingSold(let listingId), .listingReserved(let listingId):
                guard listingIdMatches(listingId) else { return }
                scheduleSilentRefresh(conversationId: conversationId, deps: deps)
                isOtherTyping = false
                deps.realtimeManager.sendTypingStop(conversationId: conversationId)
            case .listingAvailable(let listingId):
                guard listingIdMatches(listingId) else { return }
                if let d = detail, let product = d.product {
                    detail = ConversationDetail(
                        conversationId: d.conversationId,
                        otherUser: d.otherUser,
                        product: ChatProductCard(
                            listingId: product.listingId,
                            title: product.title,
                            priceVnd: product.priceVnd,
                            imageUrl: product.imageUrl,
                            listingStatus: "active"
                        ),
                        isBuyer: d.isBuyer,
                        orderId: d.orderId,
                        offerCount: 0,
                        isClosed: false,
                        pendingOffer: d.pendingOffer,
                        myReport: d.myReport
                    )
                    eventMessage = L10n.chatReopenedSnackbar
                } else {
                    scheduleSilentRefresh(conversationId: conversationId, deps: deps)
                }
            default:
                break
            }
        }
    }

    private func sameConversation(eventConvId: String, openConvId: String) -> Bool {
        let event = eventConvId.trimmingCharacters(in: .whitespacesAndNewlines)
        let open = openConvId.trimmingCharacters(in: .whitespacesAndNewlines)
        return !event.isEmpty && event.compare(open, options: .caseInsensitive) == .orderedSame
    }

    private func messageNewShouldRefreshChat(
        eventConversationId: String,
        senderId: String,
        recipientId: String,
        openConversationId: String,
        deps: AppDependencies
    ) -> Bool {
        if sameConversation(eventConvId: eventConversationId, openConvId: openConversationId) { return true }
        let eventConv = eventConversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !eventConv.isEmpty,
           eventConv.compare(openConversationId, options: .caseInsensitive) != .orderedSame {
            return false
        }
        let myId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let otherId = detail?.otherUser.userId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !myId.isEmpty, !otherId.isEmpty else { return false }
        let sender = senderId.trimmingCharacters(in: .whitespacesAndNewlines)
        let fromOther = !sender.isEmpty
            && sender.compare(otherId, options: .caseInsensitive) == .orderedSame
            && sender.compare(myId, options: .caseInsensitive) != .orderedSame
        let recipient = recipientId.trimmingCharacters(in: .whitespacesAndNewlines)
        let forMe = recipient.isEmpty || recipient.compare(myId, options: .caseInsensitive) == .orderedSame
        return fromOther && forMe
    }

    private func listingIdMatches(_ listingId: String) -> Bool {
        let lid = detail?.product?.listingId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let eventId = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        return !lid.isEmpty && lid.compare(eventId, options: .caseInsensitive) == .orderedSame
    }

    private func applyConversationClosedFromRealtime(conversationId: String, deps: AppDependencies) {
        if let d = detail {
            detail = d.withClosed(true)
        }
        inputText = ""
        showOfferSheet = false
        counterOfferSheet = nil
        isOtherTyping = false
        deps.realtimeManager.sendTypingStop(conversationId: conversationId)
    }

    private func applyConversationReopenedFromRealtime(conversationId: String) {
        if let d = detail {
            detail = d.withClosed(false).withOfferCount(0)
        }
        eventMessage = L10n.chatReopenedSnackbar
    }

    func formatTime(_ timestamp: String) -> String {
        ChatMessageTimeFormat.clockTime(timestamp)
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

    func withClosed(_ closed: Bool) -> ConversationDetail {
        ConversationDetail(
            conversationId: conversationId,
            otherUser: otherUser,
            product: product,
            isBuyer: isBuyer,
            orderId: orderId,
            offerCount: offerCount,
            isClosed: closed,
            pendingOffer: pendingOffer,
            myReport: myReport
        )
    }
}
