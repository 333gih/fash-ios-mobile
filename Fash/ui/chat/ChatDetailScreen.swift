import SwiftUI

struct ChatDetailScreen: View {
    @Environment(AppDependencies.self) private var deps
    let conversationId: String
    var onDismiss: () -> Void
    var onProductClick: (String) -> Void = { _ in }

    @State private var viewModel = ChatDetailViewModel()
    @State private var offerAmountText = ""
    @State private var counterAmountText = ""
    @State private var presentedOrderId: String?
    @State private var showFulfillmentChoiceSheet = false
    @State private var showMeetingSheet = false

    var body: some View {
        ChatDetailScreenBody(
            viewModel: viewModel,
            conversationId: conversationId,
            deps: deps,
            offerAmountText: $offerAmountText,
            counterAmountText: $counterAmountText,
            presentedOrderId: $presentedOrderId,
            showFulfillmentChoiceSheet: $showFulfillmentChoiceSheet,
            showMeetingSheet: $showMeetingSheet,
            onDismiss: onDismiss,
            onProductClick: onProductClick
        )
        .sheet(isPresented: Binding(
            get: { presentedOrderId != nil },
            set: { if !$0 { presentedOrderId = nil } }
        )) {
            if let orderId = presentedOrderId {
                OrderDetailScreen(
                    orderId: orderId,
                    onDismiss: { presentedOrderId = nil },
                    onNavigateToChat: { _ in presentedOrderId = nil },
                    onOpenListing: { listingId, _ in
                        presentedOrderId = nil
                        onProductClick(listingId)
                    },
                    onOpenUserProfile: { _ in presentedOrderId = nil }
                )
            }
        }
    }
}

private struct ChatDetailScreenBody: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var viewModel: ChatDetailViewModel
    let conversationId: String
    let deps: AppDependencies
    @Binding var offerAmountText: String
    @Binding var counterAmountText: String
    @Binding var presentedOrderId: String?
    @Binding var showFulfillmentChoiceSheet: Bool
    @Binding var showMeetingSheet: Bool
    var onDismiss: () -> Void
    var onProductClick: (String) -> Void

    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().overlay(FashColors.outlineMuted.opacity(0.72))
            if viewModel.isLoading && viewModel.detail == nil {
                Spacer()
                ProgressView().tint(FashColors.brandPrimary)
                Spacer()
            } else if let error = viewModel.loadError, viewModel.detail == nil {
                FashEmptyStateView(title: error, actionTitle: L10n.feedRetry) {
                    Task { await viewModel.load(conversationId: conversationId, deps: deps) }
                }
            } else {
                productHeader
                if viewModel.hasOrder {
                    let isBuyer = viewModel.detail?.isBuyer == true
                    let norm = ChatOrderStatusCopy.normalize(viewModel.orderStatus)
                    ChatDealBanner(
                        isBuyer: isBuyer,
                        orderStatus: viewModel.orderStatus,
                        agreedAmountVnd: viewModel.agreedAmountVnd(),
                        statusSubtitle: ChatOrderStatusCopy.subtitle(
                            isBuyer: isBuyer,
                            orderStatus: viewModel.orderStatus
                        ),
                        onViewOrder: {
                            if let oid = viewModel.orderId ?? viewModel.detail?.orderId, !oid.isEmpty {
                                presentedOrderId = oid
                            }
                        },
                        onOpenFulfillmentChoice: isBuyer && norm == "fulfillment_pending"
                            ? { showFulfillmentChoiceSheet = true }
                            : nil,
                        onScheduleMeetup: isBuyer && norm == "cash_meetup_open" && !viewModel.shouldHideScheduleMeetup
                            ? { showMeetingSheet = true }
                            : nil
                    )
                    Divider().overlay(FashColors.outlineMuted.opacity(0.5))
                }
                if viewModel.detail?.isBuyer == true, !viewModel.hasOrder {
                    ChatOfferLimitPolicyBanner(
                        usedCount: viewModel.detail?.offerCount ?? 0,
                        maxOffers: viewModel.maxOffers
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                messagesList
                if viewModel.isOtherTyping, let other = viewModel.detail?.otherUser {
                    let label = {
                        let n = other.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                        return n.isEmpty ? other.username : n
                    }()
                    ChatTypingIndicator(displayName: label)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                composer
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.isOtherTyping)
        .background(FashColors.screen)
        .task(id: conversationId) {
            await viewModel.load(conversationId: conversationId, deps: deps)
        }
        .onDisappear { viewModel.stopPolling() }
        .onChange(of: viewModel.eventMessage) { _, msg in
            guard let msg, !msg.isEmpty else { return }
            deps.uiDialog.showError(msg)
            viewModel.eventMessage = nil
        }
        .sheet(isPresented: $viewModel.showOfferSheet) {
            ChatOfferPriceSheet(
                amountText: $offerAmountText,
                listedPriceVnd: viewModel.detail?.product?.priceVnd ?? 0,
                isSubmitting: viewModel.isCreatingOffer,
                onSubmit: {
                    let digits = offerAmountText.filter(\.isNumber)
                    if let v = Int64(digits), v >= 1000 {
                        Task { await viewModel.createOffer(amountVnd: v, deps: deps) }
                    }
                },
                onDismiss: { viewModel.showOfferSheet = false }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $viewModel.counterOfferSheet) { args in
            ChatCounterOfferSheet(
                buyerAmountVnd: args.buyerOfferAmountVnd,
                amountText: $counterAmountText,
                isSubmitting: viewModel.isCreatingCounterOffer,
                onSubmit: {
                    let digits = counterAmountText.filter(\.isNumber)
                    if let v = Int64(digits), v >= 1000 {
                        Task { await viewModel.submitCounterOffer(amountVnd: v, deps: deps) }
                    }
                },
                onDismiss: { viewModel.counterOfferSheet = nil }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showFulfillmentChoiceSheet) {
            FulfillmentChoiceBottomSheet(
                shipFulfillmentEnabled: BusinessFlowConfig.c2cShipAndPaymentEnabled,
                orderCancellable: false,
                onChooseMeetup: {
                    Task {
                        if await viewModel.ensureFulfillmentCashMeetup(deps: deps) {
                            showMeetingSheet = true
                        }
                    }
                },
                onChooseShip: { }
            )
        }
        .sheet(isPresented: $showMeetingSheet) {
            MeetingProposalBottomSheet(
                conversationId: conversationId,
                linkedOrderId: viewModel.orderId,
                browseProvinceId: viewModel.meetingBrowseProvinceId,
                browseDistrictId: viewModel.meetingBrowseDistrictId,
                isLoading: viewModel.isProposingMeeting,
                onSubmit: { url, iso, reminderOn, offset, zoneId, zoneName in
                    Task {
                        if await viewModel.proposeMeeting(
                            conversationId: conversationId,
                            locationUrl: url,
                            scheduledAtIso: iso,
                            reminderEnabled: reminderOn,
                            reminderOffsetMinutes: offset,
                            safeZoneId: zoneId,
                            safeZoneName: zoneName,
                            deps: deps
                        ) {
                            showMeetingSheet = false
                        }
                    }
                }
            )
        }
        .onChange(of: showMeetingSheet) { _, open in
            if open { Task { await viewModel.loadMeetingBrowseLocation(deps: deps) } }
        }
        .alert(L10n.meetingIdentityReverifyDialogTitle, isPresented: $viewModel.showMeetingIdentityReverify) {
            Button(L10n.meetingIdentityReverifyAckDone) {
                Task { await viewModel.ackMeetingIdentityReverify(deps: deps) }
            }
            Button(L10n.meetingIdentityReverifyClose, role: .cancel) {
                viewModel.showMeetingIdentityReverify = false
            }
        } message: {
            Text(L10n.meetingIdentityReverifyDialogBody)
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            if let other = viewModel.detail?.otherUser {
                FashAvatarCircle(url: other.avatarUrl, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(other.displayName.isEmpty ? other.username : other.displayName)
                        .font(FashTypography.titleSmall)
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                    if !other.username.isEmpty {
                        Text("@\(other.username)")
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text(L10n.navChat)
                    .font(FashTypography.titleLarge)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(FashColors.surfaceContainerHighest)
    }

    @ViewBuilder
    private var productHeader: some View {
        if let product = viewModel.detail?.product, !product.listingId.isEmpty {
            Button { onProductClick(product.listingId) } label: {
                HStack(spacing: 12) {
                    ZStack(alignment: .topTrailing) {
                        FashAsyncImage(url: FeedImageUrl.resolveListingImageUrlOrNil(product.imageUrl) ?? product.imageUrl)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        if product.isSold {
                            Text(L10n.listingStatusSold)
                                .font(FashTypography.labelSmall.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.65))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .offset(x: 4, y: -4)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.title)
                            .font(FashTypography.labelLarge)
                            .foregroundStyle(FashColors.textPrimary)
                            .lineLimit(2)
                        Text(FeedPriceFormat.format(product.priceVnd))
                            .font(FashTypography.titleSmall)
                            .foregroundStyle(FashColors.brandPrimary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(FashColors.textSecondary)
                }
                .padding(12)
                .background(FashColors.surfaceContainer)
            }
            .buttonStyle(.plain)
            Divider().overlay(FashColors.outlineMuted.opacity(0.5))
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.isMessagesLoading && viewModel.messages.isEmpty {
                        ProgressView().padding(.top, 24)
                    }
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                            .id(message.messageId)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { composerFocused = false }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.messageId, anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        let isBuyer = viewModel.detail?.isBuyer == true
        switch message.messageType {
        case "offer", "counter_offer":
            ChatOfferMessageBubble(
                message: message,
                isBuyer: isBuyer,
                hasOrder: viewModel.hasOrder,
                isResponding: viewModel.isRespondingToOffer,
                formatTime: viewModel.formatTime,
                onAccept: { Task { await viewModel.acceptOffer(message, deps: deps) } },
                onDecline: { Task { await viewModel.declineOffer(message, deps: deps) } },
                onCounter: (!isBuyer && !viewModel.hasOrder && message.messageType == "offer" && !message.isFromMe)
                    ? {
                        viewModel.counterOfferSheet = CounterOfferSheetArgs(
                            buyerOfferMessageId: message.messageId,
                            buyerOfferAmountVnd: message.offerAmountVnd
                        )
                    }
                    : nil
            )
        case "order_cancelled":
            if let payload = message.orderCancelled
                ?? OrderCancelledChatPayload.parse(messageType: message.messageType, fullText: message.text) {
                ChatOrderCancelledCardBubble(
                    message: message,
                    payload: payload,
                    isBuyer: isBuyer,
                    formatTime: viewModel.formatTime,
                    onViewOrder: { presentedOrderId = payload.orderId }
                )
            }
        case "system":
            ChatSystemMessageBubble(
                text: message.text,
                timestamp: message.timestamp,
                formatTime: viewModel.formatTime
            )
        case "meeting_proposal":
            if let appt = message.meetingAppointment {
                ChatMeetingProposalCard(
                    message: message,
                    appointment: appt,
                    isViewerBuyer: isBuyer,
                    hasLinkedEscrowOrder: viewModel.hasOrder,
                    formatTime: viewModel.formatTime,
                    mutationInFlight: viewModel.meetingMutationInFlight,
                    onConfirm: { Task { await viewModel.confirmMeeting(appointmentId: appt.appointmentId, deps: deps) } },
                    onWithdrawOrReject: { Task { await viewModel.cancelMeeting(appointmentId: appt.appointmentId, deps: deps) } },
                    onOnMyWay: appt.status.lowercased() == "confirmed"
                        ? { Task { await viewModel.onMyWayMeeting(appointmentId: appt.appointmentId, deps: deps) } }
                        : nil,
                    onCheckIn: appt.status.lowercased() == "confirmed"
                        ? { Task { await viewModel.checkInMeeting(appointmentId: appt.appointmentId, deps: deps) } }
                        : nil
                )
            } else if !message.text.isEmpty {
                ChatSystemMessageBubble(
                    text: message.text,
                    timestamp: message.timestamp,
                    formatTime: viewModel.formatTime
                )
            }
        default:
            if let legacy = OrderCancelledChatPayload.parse(messageType: "text", fullText: message.text) {
                ChatOrderCancelledCardBubble(
                    message: message,
                    payload: legacy,
                    isBuyer: isBuyer,
                    formatTime: viewModel.formatTime,
                    onViewOrder: { presentedOrderId = legacy.orderId }
                )
            } else if !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                textBubble(message)
            }
        }
    }

    private func textBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isFromMe { Spacer(minLength: 48) }
            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(message.isFromMe ? Color.white : FashColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(message.isFromMe ? FashColors.brandPrimary : FashColors.surfaceContainerHigh)
                    )
                HStack(spacing: 6) {
                    if message.outboundState == .sending {
                        ProgressView().scaleEffect(0.7)
                    } else if message.outboundState == .failed {
                        Text(L10n.chatSendError)
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(FashColors.error)
                    }
                    Text(viewModel.formatTime(message.timestamp))
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
            if !message.isFromMe { Spacer(minLength: 48) }
        }
    }

    private var composer: some View {
        let readOnly = viewModel.detail?.isClosed == true || viewModel.detail?.product?.isSold == true
        let trimmed = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(spacing: 10) {
            if viewModel.canShowOfferButton(deps: deps) {
                Button {
                    offerAmountText = ""
                    viewModel.showOfferSheet = true
                } label: {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(width: 40, height: 40)
                }
                .disabled(viewModel.isCreatingOffer)
            }
            TextField(L10n.chatInputHint, text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .focused($composerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .disabled(readOnly)
                .onChange(of: viewModel.inputText) { _, _ in
                    viewModel.onInputChange(deps: deps)
                }
            Button {
                composerFocused = false
                Task { await viewModel.sendMessage(deps: deps) }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(FashColors.brandPrimary.opacity(readOnly || trimmed.isEmpty ? 0.4 : 1))
                    .clipShape(Circle())
            }
            .disabled(readOnly || trimmed.isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FashColors.surfaceContainerHighest)
    }
}
