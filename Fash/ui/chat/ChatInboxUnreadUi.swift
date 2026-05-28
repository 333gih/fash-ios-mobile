import SwiftUI

enum ChatInboxUnreadUi {
    static func formatUnreadBadgeCount(_ count: Int) -> String {
        if count <= 0 { return "" }
        if count > 99 { return "99+" }
        return "\(count)"
    }
}

struct ChatInboxUnreadBanner: View {
    let unreadTotal: Int

    var body: some View {
        if unreadTotal > 0 {
            HStack(spacing: 10) {
                Image(systemName: "message.badge")
                    .font(.system(size: 20))
                    .foregroundStyle(FashColors.brandPrimary)
                Text(L10n.chatInboxUnreadBanner(unreadTotal))
                    .font(FashTypography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(FashColors.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FashColors.brandPrimary.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct ChatConversationAvatarWithUnread<Avatar: View>: View {
    let hasUnread: Bool
    let unreadCount: Int
    @ViewBuilder var avatar: () -> Avatar

    var body: some View {
        ZStack(alignment: .topTrailing) {
            avatar()
            if unreadCount > 0 {
                Text(ChatInboxUnreadUi.formatUnreadBadgeCount(unreadCount))
                    .font(FashTypography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(FashColors.readableOnBrandPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(FashColors.brandPrimary)
                    .clipShape(Capsule())
                    .offset(x: 6, y: -4)
                    .accessibilityLabel(L10n.chatUnreadMessagesCd(unreadCount))
            } else if hasUnread {
                Circle()
                    .fill(FashColors.brandPrimary)
                    .frame(width: 10, height: 10)
                    .offset(x: 4, y: -2)
                    .accessibilityLabel(L10n.chatHasUnreadCd)
            }
        }
    }
}
