import SwiftUI

struct NotificationScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @State private var viewModel: NotificationsViewModel
    var promoSlides: [FashPromoSlideDef] = []
    var onPromoSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }
    var detailId: String?
    var onDismiss: () -> Void
    var onOpenOrder: (String) -> Void = { _ in }
    var onOpenListing: (String) -> Void = { _ in }
    var onOpenChat: (String) -> Void = { _ in }

    init(
        userRepository: UserRepository,
        promoSlides: [FashPromoSlideDef] = [],
        onPromoSlideClick: @escaping (FashPromoSlideDef, Int) -> Void = { _, _ in },
        detailId: String? = nil,
        onDismiss: @escaping () -> Void,
        onOpenOrder: @escaping (String) -> Void = { _ in },
        onOpenListing: @escaping (String) -> Void = { _ in },
        onOpenChat: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: NotificationsViewModel(userRepository: userRepository))
        self.promoSlides = promoSlides
        self.onPromoSlideClick = onPromoSlideClick
        self.detailId = detailId
        self.onDismiss = onDismiss
        self.onOpenOrder = onOpenOrder
        self.onOpenListing = onOpenListing
        self.onOpenChat = onOpenChat
    }

    private var showPromoFooter: Bool {
        !promoSlides.isEmpty && viewModel.selectedGroup == nil && viewModel.selectedDetailId == nil && detailId == nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                Group {
                    if let detailId = viewModel.selectedDetailId ?? detailId {
                        detailContent(detailId)
                    } else if viewModel.selectedGroup == nil {
                        groupList
                    } else {
                        groupDetail
                    }
                }
                .navigationTitle(viewModel.selectedGroup.map(notificationGroupTitle) ?? L10n.notifications)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if viewModel.selectedDetailId == nil && detailId == nil {
                            Button {
                                if viewModel.selectedGroup != nil {
                                    viewModel.closeGroup()
                                } else {
                                    onDismiss()
                                }
                            } label: {
                                FashBackButton.toolbarLabel()
                            }
                            .accessibilityLabel(L10n.cdBack)
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
                            .font(FashTypography.labelLarge.weight(.semibold))
                            .foregroundStyle(FashColors.brandPrimary)
                        }
                    }
                }
                .task {
                    await viewModel.refresh()
                    if let detailId, !detailId.isEmpty {
                        viewModel.openDetail(detailId)
                    }
                }
                .onChange(of: deps.inboxUnreadRefreshGeneration) { _, _ in
                    Task { await viewModel.refresh() }
                }
            }
            if showPromoFooter {
                FashPromoSliderAdFooterView(slides: promoSlides, onSlideClick: onPromoSlideClick)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(FashColors.screen)
    }

    @ViewBuilder
    private func detailContent(_ detailId: String) -> some View {
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
    }

    private var groupList: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.groups.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
            } else if let error = viewModel.loadError, viewModel.groups.isEmpty {
                FashEmptyStateView(
                    title: viewModel.inboxUnavailable ? L10n.notificationInboxUnavailableTitle : L10n.notificationLoadErrorTitle,
                    subtitle: viewModel.inboxUnavailable ? L10n.notificationInboxUnavailableSubtitle : (error.isEmpty ? L10n.notificationLoadErrorSubtitle : error),
                    actionTitle: L10n.feedRetry
                ) {
                    Task { await viewModel.refresh() }
                }
                .padding(.top, 24)
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.groups) { group in
                        Button {
                            viewModel.openGroup(group.group)
                        } label: {
                            groupRow(group)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.vertical, 8)
                .padding(.bottom, showPromoFooter ? FashStickyPromoDockHeight : 16)
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
        .listStyle(.plain)
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private func groupRow(_ group: NotificationGroupSummaryItem) -> some View {
        let preview = group.latestBody?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? group.latestTitle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? notificationGroupSubtitle(group.group)
        HStack(spacing: 10) {
            Image(systemName: notificationGroupSystemImage(group.group))
                .font(.system(size: 20))
                .foregroundStyle(FashColors.textSecondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(notificationGroupTitle(group.group))
                        .font(FashTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                    if group.unreadCount > 0 {
                        Text("\(min(group.unreadCount, 99))")
                            .font(FashTypography.labelSmall.weight(.bold))
                            .foregroundStyle(FashColors.readableOnBrandPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 1)
                            .background(FashColors.brandPrimary)
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                }
                Text(preview)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .lineLimit(1)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: NotificationGroups.rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
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
                        image.resizable().aspectRatio(contentMode: .fill)
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

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
