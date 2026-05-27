import SwiftUI

/// Bottom navigation — Android [MainNavBottomBar].
struct MainNavBottomBar: View {
    @Binding var selectedTab: MainTab
    var chatUnreadCount: Int = 0
    var onTabChange: (MainTab) -> Void
    var onTabReselected: ((MainTab) -> Void)? = nil

    private let iconSize: CGFloat = 26
    private let fabSize: CGFloat = 52
    private let iconLabelGap: CGFloat = 4
    private let slotMinHeight: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(FashColors.outlineMuted.opacity(0.72))
            HStack(alignment: .center, spacing: 0) {
                sideItem(tab: .home)
                sideItem(tab: .explore)
                postFab
                sideItem(tab: .chat)
                sideItem(tab: .profile)
            }
            .frame(minHeight: 72)
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
        }
        .background(FashColors.surfaceContainerHighest)
    }

    @ViewBuilder
    private func sideItem(tab: MainTab) -> some View {
        let selected = selectedTab == tab
        let tint = selected ? FashColors.brandPrimary : FashColors.textSecondary
        Button {
            if selected {
                onTabReselected?(tab)
            } else {
                onTabChange(tab)
            }
        } label: {
            VStack(spacing: iconLabelGap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon(for: tab))
                        .font(.system(size: iconSize))
                        .foregroundStyle(tint)
                    if tab == .chat, chatUnreadCount > 0 {
                        Text(chatUnreadCount > 99 ? "99+" : "\(chatUnreadCount)")
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(FashColors.brandPrimary)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
                .frame(height: iconSize)
                Text(label(for: tab))
                    .font(FashTypography.labelSmall)
                    .fontWeight(selected ? .semibold : .medium)
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: slotMinHeight)
        }
        .buttonStyle(.plain)
    }

    private var postFab: some View {
        let selected = selectedTab == .post
        return Button {
            if selected {
                onTabReselected?(.post)
            } else {
                onTabChange(.post)
            }
        } label: {
            VStack(spacing: iconLabelGap) {
                ZStack {
                    Circle()
                        .fill(FashColors.brandPrimary)
                        .frame(width: fabSize, height: fabSize)
                        .shadow(color: FashColors.brandPrimary.opacity(0.16), radius: selected ? 8 : 5, y: 2)
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(L10n.navPostFabLabel)
                    .font(FashTypography.labelSmall)
                    .fontWeight(selected ? .bold : .semibold)
                    .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: slotMinHeight)
        }
        .buttonStyle(.plain)
    }

    private func icon(for tab: MainTab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .explore: return "safari.fill"
        case .post: return "plus"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }

    private func label(for tab: MainTab) -> String {
        switch tab {
        case .home: return L10n.navHome
        case .explore: return L10n.navExplore
        case .post: return L10n.navPost
        case .chat: return L10n.navChat
        case .profile: return L10n.navProfile
        }
    }
}
