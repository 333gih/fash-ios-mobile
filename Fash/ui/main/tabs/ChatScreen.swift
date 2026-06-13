import SwiftUI

struct ChatScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ChatViewModel
    var promoSlides: [FashPromoSlideDef] = []
    var onPromoSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }
    var onConversationTap: (String) -> Void

    @State private var chatScrollTopId = UUID()

    private var showGroupedInbox: Bool {
        viewModel.sellerHasActiveListings && viewModel.sellerInboxGroupMode == .byProduct
    }

    private var promoDockInset: CGFloat {
        promoSlides.isEmpty ? 0 : FashStickyPromoDockHeight
    }

    private var isEmptyInbox: Bool {
        if showGroupedInbox {
            return viewModel.displayGroups.isEmpty
        }
        return viewModel.conversations.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ChatInboxFilterBar(
                    selectedFilter: viewModel.selectedFilter,
                    sellerHasActiveListings: viewModel.sellerHasActiveListings,
                    groupByProductSelected: viewModel.sellerInboxGroupMode == .byProduct,
                    onFilterClick: { viewModel.setFilter($0) },
                    onGroupByProductClick: {
                        Task {
                            let next: SellerInboxGroupMode = viewModel.sellerInboxGroupMode == .byProduct
                                ? .allConversations
                                : .byProduct
                            await viewModel.setSellerInboxGroupMode(next, deps: deps)
                        }
                    }
                )

                if viewModel.unreadTotal > 0 {
                    ChatInboxUnreadBanner(unreadTotal: viewModel.unreadTotal)
                        .padding(.horizontal, spacing.editorialStart)
                        .padding(.bottom, 4)
                }

                inboxContent
                    .padding(.bottom, promoDockInset)
            }

            if !promoSlides.isEmpty {
                StickyBottomPromoBar {
                    FashPromoSliderView(
                        slides: promoSlides,
                        onSlideClick: onPromoSlideClick
                    )
                }
            }
        }
        .background(FashColors.screen)
        .task { await viewModel.loadConversationsWhenNeeded(deps: deps) }
        .onChange(of: viewModel.chatScrollToTopToken) { _, _ in
            chatScrollTopId = UUID()
        }
    }

    @ViewBuilder
    private var inboxContent: some View {
        if viewModel.isLoading && isEmptyInbox && !viewModel.isRefreshing {
            chatPullScrollContainer {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 320)
            }
        } else if viewModel.loadError && isEmptyInbox {
            chatPullScrollContainer {
                FashEmptyStateView(
                    title: L10n.chatLoadError,
                    actionTitle: L10n.chatRetry
                ) {
                    Task { await viewModel.loadConversations(deps: deps) }
                }
                .frame(maxWidth: .infinity, minHeight: 320)
            }
        } else if isEmptyInbox {
            chatPullScrollContainer {
                ChatEmptyInboxHint()
                    .frame(maxWidth: .infinity, minHeight: 320)
            }
        } else if showGroupedInbox {
            groupedList
        } else {
            flatList
        }
    }

    private func chatPullScrollContainer<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ChatInboxScrollContainer(
            scrollTopId: chatScrollTopId,
            scrollToTopToken: viewModel.chatScrollToTopToken,
            isRefreshing: $viewModel.isRefreshing,
            onRefresh: { await viewModel.pullToRefresh(deps: deps) },
            content: content
        )
    }

    private var flatList: some View {
        ChatInboxScrollContainer(
            scrollTopId: chatScrollTopId,
            scrollToTopToken: viewModel.chatScrollToTopToken,
            isRefreshing: $viewModel.isRefreshing,
            onRefresh: { await viewModel.pullToRefresh(deps: deps) }
        ) {
            ForEach(viewModel.conversations) { item in
                ChatConversationRow(
                    item: item,
                    formatTimestamp: viewModel.formatTimestamp,
                    previewLine: viewModel.conversationPreviewLine(item),
                    previewIsPlaceholder: viewModel.conversationPreviewIsPlaceholder(item),
                    onClick: { onConversationTap(item.conversationId) }
                )
            }
        }
    }

    private var groupedList: some View {
        ChatInboxScrollContainer(
            scrollTopId: chatScrollTopId,
            scrollToTopToken: viewModel.chatScrollToTopToken,
            isRefreshing: $viewModel.isRefreshing,
            onRefresh: { await viewModel.pullToRefresh(deps: deps) }
        ) {
            ForEach(viewModel.displayGroups) { group in
                ChatListingGroupHeader(
                    group: group,
                    expanded: viewModel.expandedGroupListingIds.contains(group.listingId),
                    formatPrice: viewModel.formatPriceVnd,
                    onToggle: { viewModel.toggleListingGroupExpanded(group.listingId) }
                )
                if viewModel.expandedGroupListingIds.contains(group.listingId) {
                    ForEach(group.conversations) { item in
                        ChatConversationRow(
                            item: item,
                            formatTimestamp: viewModel.formatTimestamp,
                            previewLine: viewModel.conversationPreviewLine(item),
                            previewIsPlaceholder: viewModel.conversationPreviewIsPlaceholder(item),
                            onClick: { onConversationTap(item.conversationId) }
                        )
                    }
                }
            }
        }
    }

}

/// Scroll-to-top for chat inbox lists (struct avoids ViewBuilder escaping issues in `ScrollViewReader`).
private struct ChatInboxScrollContainer<Content: View>: View {
    let scrollTopId: UUID
    let scrollToTopToken: Int
    @Binding var isRefreshing: Bool
    var onRefresh: () async -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear.frame(height: 0).id(scrollTopId)
                LazyVStack(spacing: 8) {
                    content()
                }
                .padding(.bottom, 8)
            }
            .fashFeedPullRefresh(isRefreshing: $isRefreshing, onRefresh: onRefresh)
            .onChange(of: scrollToTopToken) { _, _ in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    proxy.scrollTo(scrollTopId, anchor: .top)
                }
            }
        }
    }
}
