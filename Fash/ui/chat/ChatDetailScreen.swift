import SwiftUI

struct ChatDetailScreen: View {
    @Environment(AppDependencies.self) private var deps
    let conversationId: String
    var onDismiss: () -> Void
    var onProductClick: (String) -> Void = { _ in }

    @State private var viewModel = ChatDetailViewModel()

    var body: some View {
        ChatDetailScreenBody(
            viewModel: viewModel,
            conversationId: conversationId,
            deps: deps,
            onDismiss: onDismiss,
            onProductClick: onProductClick
        )
    }
}

private struct ChatDetailScreenBody: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var viewModel: ChatDetailViewModel
    let conversationId: String
    let deps: AppDependencies
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
                messagesList
                composer
            }
        }
        .background(FashColors.screen)
        .task(id: conversationId) {
            await viewModel.load(conversationId: conversationId, deps: deps)
        }
        .onDisappear {
            viewModel.stopPolling()
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
            Button {
                onProductClick(product.listingId)
            } label: {
                HStack(spacing: 12) {
                    FashAsyncImage(url: FeedImageUrl.resolveListingImageUrlOrNil(product.imageUrl) ?? product.imageUrl)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    ForEach(viewModel.messages.filter { $0.messageType == "text" || $0.messageType.isEmpty }) { message in
                        messageBubble(message)
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

    private func messageBubble(_ message: ChatMessage) -> some View {
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
        let readOnly = viewModel.detail?.isClosed == true || viewModel.detail?.product?.listingStatus == "sold"
        let trimmed = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(spacing: 10) {
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
