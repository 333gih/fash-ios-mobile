import SwiftUI

struct ChatScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ChatViewModel
    var promoSlides: [FashPromoSlideDef] = []
    var onPromoSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }
    var onConversationTap: (String) -> Void

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
        .refreshable { await viewModel.pullToRefresh(deps: deps) }
    }

    @ViewBuilder
    private var inboxContent: some View {
        if viewModel.isLoading && isEmptyInbox && !viewModel.isRefreshing {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.loadError && isEmptyInbox {
            FashEmptyStateView(
                title: L10n.chatLoadError,
                actionTitle: L10n.chatRetry
            ) {
                Task { await viewModel.loadConversations(deps: deps) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isEmptyInbox {
            ChatEmptyInboxHint()
        } else if showGroupedInbox {
            groupedList
        } else {
            flatList
        }
    }

    private var flatList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
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
            .padding(.bottom, 8)
        }
    }

    private var groupedList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
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
            .padding(.bottom, 8)
        }
    }
}
