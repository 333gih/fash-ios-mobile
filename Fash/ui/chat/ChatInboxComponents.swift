import SwiftUI

struct ChatInboxFilterBar: View {
    @Environment(\.fashSpacing) private var spacing
    let selectedFilter: ChatFilter
    let sellerHasActiveListings: Bool
    let groupByProductSelected: Bool
    var onFilterClick: (ChatFilter) -> Void
    var onGroupByProductClick: () -> Void

    private let chipCorner: CGFloat = 20

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(L10n.chatFilterAll, selected: selectedFilter == .all) { onFilterClick(.all) }
                filterChip(L10n.chatFilterUnread, selected: selectedFilter == .unread) { onFilterClick(.unread) }
                filterChip(L10n.chatFilterSeller, selected: selectedFilter == .seller) { onFilterClick(.seller) }
                filterChip(L10n.chatFilterBuyer, selected: selectedFilter == .buyer) { onFilterClick(.buyer) }
                if sellerHasActiveListings {
                    filterChip(
                        L10n.chatInboxByProduct,
                        selected: groupByProductSelected,
                        action: onGroupByProductClick
                    )
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, 12)
        }
    }

    private func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(FashTypography.labelMedium)
                .fontWeight(.medium)
                .foregroundStyle(selected ? FashColors.readableOnBrandPrimary : FashColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selected ? FashColors.brandPrimary : FashColors.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: chipCorner, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ChatListingGroupHeader: View {
    @Environment(\.fashSpacing) private var spacing
    let group: ConversationListingGroup
    let expanded: Bool
    let formatPrice: (Int64) -> String
    var onToggle: () -> Void

    private var groupUnreadTotal: Int {
        group.conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                groupThumb
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title.isEmpty ? "—" : group.title)
                        .font(FashTypography.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(formatPrice(group.priceVnd))
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.brandPrimary)
                }
                Spacer(minLength: 0)
                if groupUnreadTotal > 0 {
                    Text(ChatInboxUnreadUi.formatUnreadBadgeCount(groupUnreadTotal))
                        .font(FashTypography.labelSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(FashColors.readableOnBrandPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FashColors.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
                        .accessibilityLabel(L10n.chatGroupUnreadCd(groupUnreadTotal))
                }
                Text("\(max(group.conversationCountBadge, 0))")
                    .font(FashTypography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(FashColors.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FashColors.brandPrimary.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.10), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var groupThumb: some View {
        let url = FeedImageUrl.resolveListingImageUrlOrNil(group.coverImageUrl)
        Group {
            if let url {
                FashAsyncImage(url: url)
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .frame(width: 48, height: 48)
        .background(FashColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
    }
}

struct ChatConversationRow: View {
    @Environment(\.fashSpacing) private var spacing
    let item: ConversationItem
    let formatTimestamp: (String) -> String
    let previewLine: String
    let previewIsPlaceholder: Bool
    var onClick: () -> Void

    private let avatarSize: CGFloat = 48
    private let productThumbSize: CGFloat = 56

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                if item.hasUnread {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(FashColors.brandPrimary)
                        .frame(width: 2, height: 40)
                }
                ChatConversationAvatarWithUnread(hasUnread: item.hasUnread, unreadCount: item.unreadCount) {
                    FashAvatarCircle(url: item.avatarUrl, size: avatarSize)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center) {
                        Text(displayName)
                            .font(FashTypography.titleSmall)
                            .fontWeight(item.hasUnread ? .heavy : .bold)
                            .foregroundStyle(item.hasUnread ? FashColors.textPrimary : FashColors.textPrimary.opacity(0.88))
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(formatTimestamp(item.timestamp))
                            .font(FashTypography.labelSmall)
                            .fontWeight(item.hasUnread ? .semibold : .medium)
                            .foregroundStyle(item.hasUnread ? FashColors.brandPrimary : FashColors.textSecondary.opacity(0.90))
                    }
                    previewContent
                }
                productThumb
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(item.hasUnread ? FashColors.brandPrimary.opacity(0.10) : FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                    .stroke(
                        item.hasUnread ? FashColors.brandPrimary.opacity(0.14) : FashColors.outlineMuted.opacity(0.10),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, 4)
    }

    private var displayName: String {
        if !item.displayName.isEmpty { return item.displayName }
        let user = item.username.isEmpty ? "user" : item.username
        return "@\(user)"
    }

    @ViewBuilder
    private var previewContent: some View {
        if previewIsPlaceholder {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 14))
                    .foregroundStyle(FashColors.brandPrimary.opacity(0.72))
                Text(previewLine)
                    .font(FashTypography.bodyMedium)
                    .italic()
                    .foregroundStyle(FashColors.textSecondary.opacity(0.92))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        } else {
            Text(previewLine)
                .font(FashTypography.bodyMedium)
                .fontWeight(item.hasUnread ? .semibold : .regular)
                .foregroundStyle(item.hasUnread ? FashColors.textPrimary : FashColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var productThumb: some View {
        let url = FeedImageUrl.resolveListingImageUrlOrNil(item.productThumbnailUrl)
        Group {
            if let url {
                FashAsyncImage(url: url)
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .frame(width: productThumbSize, height: productThumbSize)
        .background(FashColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
                .stroke(FashColors.outlineMuted.opacity(0.18), lineWidth: 1)
        }
    }
}

struct ChatEmptyInboxHint: View {
    var body: some View {
        VStack(spacing: 12) {
            FashEmptyStateView(
                title: L10n.chatEmpty,
                subtitle: L10n.chatEmptySubtitle,
                systemImage: "bubble.left.and.bubble.right"
            )
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.chatEmptySuggestionsTitle)
                    .font(FashTypography.labelLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ChatEmptyBulletTipLine(text: L10n.chatEmptyTip1)
                ChatEmptyBulletTipLine(text: L10n.chatEmptyTip2)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ChatEmptyBulletTipLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(FashColors.brandPrimary)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
