import SwiftUI

struct NotificationScreen: View {
    @State private var viewModel: NotificationsViewModel
    var detailId: String?
    var onDismiss: () -> Void
    var onOpenOrder: (String) -> Void = { _ in }
    var onOpenListing: (String) -> Void = { _ in }
    var onOpenChat: (String) -> Void = { _ in }

    init(
        userRepository: UserRepository,
        detailId: String? = nil,
        onDismiss: @escaping () -> Void,
        onOpenOrder: @escaping (String) -> Void = { _ in },
        onOpenListing: @escaping (String) -> Void = { _ in },
        onOpenChat: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: NotificationsViewModel(userRepository: userRepository))
        self.detailId = detailId
        self.onDismiss = onDismiss
        self.onOpenOrder = onOpenOrder
        self.onOpenListing = onOpenListing
        self.onOpenChat = onOpenChat
    }

    var body: some View {
        NavigationStack {
            Group {
                if let detailId = viewModel.selectedDetailId ?? detailId {
                    if let item = viewModel.selectedDetailItem ?? viewModel.items.first(where: { $0.id == detailId }) {
                        NotificationDetailScreen(
                            item: item,
                            onDismiss: {
                                viewModel.closeDetail()
                                if self.detailId != nil { onDismiss() }
                            },
                            onOpenOrder: onOpenOrder,
                            onOpenListing: onOpenListing,
                            onOpenChat: onOpenChat
                        )
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .task {
                                await viewModel.refresh()
                                if let item = viewModel.items.first(where: { $0.id == detailId }) {
                                    viewModel.openDetail(item)
                                }
                            }
                    }
                } else if viewModel.selectedGroup == nil {
                    groupList
                } else {
                    groupDetail
                }
            }
            .navigationTitle(viewModel.selectedGroup.map(notificationGroupTitle) ?? L10n.notifications)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if viewModel.selectedGroup != nil {
                            viewModel.closeGroup()
                        } else {
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                if viewModel.selectedGroup != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.notificationMarkAllRead) {
                            Task { await viewModel.markAllRead() }
                        }
                        .disabled(
                            viewModel.markAllReadBusy ||
                            !viewModel.canMarkAllReadInSelectedGroup
                        )
                    }
                }
            }
            .task {
                await viewModel.refresh()
                if let detailId, !detailId.isEmpty {
                    viewModel.openDetail(detailId)
                }
            }
        }
    }

    private var groupList: some View {
        List {
            if viewModel.isLoading && viewModel.groups.isEmpty {
                ProgressView().frame(maxWidth: .infinity)
            } else if let error = viewModel.loadError, viewModel.groups.isEmpty {
                FashEmptyStateView(
                    title: viewModel.inboxUnavailable ? L10n.notificationInboxUnavailableTitle : L10n.notificationLoadErrorTitle,
                    subtitle: viewModel.inboxUnavailable ? L10n.notificationInboxUnavailableSubtitle : (error.isEmpty ? L10n.notificationLoadErrorSubtitle : error),
                    actionTitle: L10n.feedRetry
                ) {
                    Task { await viewModel.refresh() }
                }
            } else {
                ForEach(viewModel.groups) { group in
                    Button {
                        viewModel.openGroup(group.group)
                    } label: {
                        groupRow(group)
                    }
                }
            }
        }
        .refreshable { await viewModel.refresh() }
    }

    private var groupDetail: some View {
        List {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView().frame(maxWidth: .infinity)
            } else if viewModel.items.isEmpty {
                FashEmptyStateView(
                    title: L10n.notificationGroupEmptyTitle,
                    subtitle: L10n.notificationEmptySubtitle
                )
            } else {
                ForEach(viewModel.items) { item in
                    Button {
                        viewModel.openDetail(item)
                        Task { await viewModel.markReadIfNeeded(item) }
                    } label: {
                        notificationRow(item)
                    }
                }
                if viewModel.loadMoreBusy {
                    ProgressView().frame(maxWidth: .infinity)
                } else if viewModel.hasMore {
                    Color.clear.frame(height: 1).onAppear {
                        Task { await viewModel.loadMore() }
                    }
                }
            }
        }
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private func groupRow(_ group: NotificationGroupSummaryItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: notificationGroupSystemImage(group.group))
                .foregroundStyle(FashColors.textSecondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(notificationGroupTitle(group.group))
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                    if group.unreadCount > 0 {
                        Text("\(min(group.unreadCount, 99))")
                            .font(FashTypography.labelLarge)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 1)
                            .background(FashColors.brandPrimary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                }
                Text(group.latestBody ?? group.latestTitle ?? notificationGroupSubtitle(group.group))
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                    .lineLimit(1)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(FashColors.textSecondary)
                .font(.caption)
        }
        .frame(height: NotificationGroups.rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func notificationRow(_ item: InboxNotificationItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notificationPayloadSystemImage(item.payloadType))
                .foregroundStyle(FashColors.brandPrimary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title.isEmpty ? L10n.notificationDetailNoTitle : item.title)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.textPrimary)
                Text(item.body)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                    .lineLimit(3)
                if item.isUnread {
                    Text(L10n.notificationUnreadBadge)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                }
            }
            if let url = notificationRowImageURL(item) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color.gray.opacity(0.15)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 4)
    }
}
