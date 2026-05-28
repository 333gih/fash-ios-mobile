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

    var body: some View {
        ChatDetailScreenBody(
            viewModel: viewModel,
            conversationId: conversationId,
            deps: deps,
            offerAmountText: $offerAmountText,
            counterAmountText: $counterAmountText,
            presentedOrderId: $presentedOrderId,
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
                    ChatDealBanner(
                        isBuyer: viewModel.detail?.isBuyer == true,
                        orderStatus: viewModel.orderStatus,
                        agreedAmountVnd: viewModel.agreedAmountVnd(),
                        statusSubtitle: ChatOrderStatusCopy.subtitle(
                            isBuyer: viewModel.detail?.isBuyer == true,
                            orderStatus: viewModel.orderStatus
                        ),
                        onViewOrder: {
                            if let oid = viewModel.orderId ?? viewModel.detail?.orderId, !oid.isEmpty {
                                presentedOrderId = oid
                            }
                        }
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
                composer
            }
        }
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
                onCounter: isBuyer ? nil : {
                    viewModel.counterOfferSheet = CounterOfferSheetArgs(
                        buyerOfferMessageId: message.messageId,
                        buyerOfferAmountVnd: message.offerAmountVnd
                    )
                }
            )
        case "system":
            ChatSystemMessageBubble(text: message.text.isEmpty ? (message.systemSubtype ?? "") : message.text)
        case "meeting_proposal":
            if let appt = message.meetingAppointment {
                ChatMeetingProposalCard(appointment: appt, formatTime: viewModel.formatTime)
            } else {
                ChatSystemMessageBubble(text: message.text)
            }
        default:
            textBubble(message)
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
