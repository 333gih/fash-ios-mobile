import SwiftUI

struct ChatScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ChatViewModel
    var onConversationTap: (String) -> Void

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.loadError && viewModel.conversations.isEmpty {
                FashEmptyStateView(
                    title: L10n.feedLoadError,
                    actionTitle: L10n.feedRetry
                ) {
                    Task { await viewModel.refresh(deps: deps) }
                }
            } else if viewModel.conversations.isEmpty {
                FashEmptyStateView(
                    title: L10n.chatEmpty,
                    subtitle: L10n.chatEmptySubtitle
                )
            } else {
                List(viewModel.conversations) { conversation in
                    Button {
                        onConversationTap(conversation.conversationId)
                    } label: {
                        HStack(spacing: 12) {
                            FashAvatarCircle(url: conversation.avatarUrl, size: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(conversation.displayName.isEmpty ? conversation.username : conversation.displayName)
                                        .font(FashTypography.titleSmall)
                                        .foregroundStyle(FashColors.textPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    if conversation.hasUnread {
                                        Text("\(max(conversation.unreadCount, 1))")
                                            .font(FashTypography.labelSmall)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(FashColors.brandPrimary)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(conversation.lastMessageText.isEmpty ? conversation.productTitle : conversation.lastMessageText)
                                    .font(FashTypography.bodySmall)
                                    .foregroundStyle(FashColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowSeparatorTint(FashColors.outlineMuted)
                }
                .listStyle(.plain)
            }
        }
        .task { await viewModel.refresh(deps: deps) }
        .refreshable { await viewModel.pullToRefresh(deps: deps) }
    }
}
