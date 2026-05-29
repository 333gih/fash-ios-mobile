import SwiftUI

/// Bottom tab bar — compact layout aligned with Material nav density, refined for iOS.
struct MainNavBottomBar: View {
    @Binding var selectedTab: MainTab
    var chatUnreadCount: Int = 0
    var isPostListingFlow: Bool = false
    var onTabChange: (MainTab) -> Void
    var onTabReselected: ((MainTab) -> Void)? = nil

    /// Total bar content height (divider + row); use for overlay insets (~58pt + safe area).
    static let contentHeight: CGFloat = 58

    private let iconSize: CGFloat = 20
    private let iconSlotHeight: CGFloat = 28
    private let fabSize: CGFloat = 44
    private let fabIconSize: CGFloat = 20
    private let iconLabelGap: CGFloat = 2
    private let rowMinHeight: CGFloat = 48
    private let labelSize: CGFloat = 10

    var body: some View {
        if isPostListingFlow {
            EmptyView()
        } else {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(FashColors.outlineMuted.opacity(0.35))
                    .frame(height: 0.5)

                HStack(alignment: .center, spacing: 0) {
                    sideItem(tab: .home)
                    sideItem(tab: .orders)
                    postFab
                    sideItem(tab: .chat)
                    sideItem(tab: .profile)
                }
                .frame(minHeight: rowMinHeight)
                .padding(.horizontal, 4)
                .padding(.top, 6)
                .padding(.bottom, 4)
            }
            .background {
                FashColors.screen
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    @ViewBuilder
    private func sideItem(tab: MainTab) -> some View {
        let selected = selectedTab == tab
        let tint = selected ? FashColors.brandPrimary : FashColors.textSecondary.opacity(0.88)

        Button {
            if selected {
                onTabReselected?(tab)
            } else {
                onTabChange(tab)
            }
        } label: {
            VStack(spacing: iconLabelGap) {
                ZStack {
                    if selected {
                        Capsule()
                            .fill(FashColors.brandPrimary.opacity(0.14))
                            .frame(width: 52, height: iconSlotHeight)
                    }
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: icon(for: tab, selected: selected))
                            .font(.system(size: iconSize, weight: selected ? .semibold : .regular))
                            .foregroundStyle(tint)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: iconSize, height: iconSize)

                        if tab == .chat, chatUnreadCount > 0 {
                            Text(chatUnreadCount > 99 ? "99+" : "\(chatUnreadCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(FashColors.readableOnBrandPrimary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(FashColors.brandPrimary)
                                .clipShape(Capsule())
                                .offset(x: 7, y: -5)
                        }
                    }
                }
                .frame(height: iconSlotHeight)

                Text(label(for: tab))
                    .font(.system(size: labelSize, weight: selected ? .semibold : .medium))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(MainNavTabButtonStyle())
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
            ZStack {
                Circle()
                    .fill(FashColors.brandPrimary)
                    .frame(width: fabSize, height: fabSize)
                    .shadow(
                        color: FashColors.brandPrimary.opacity(selected ? 0.22 : 0.14),
                        radius: selected ? 6 : 4,
                        y: 2
                    )
                Image(systemName: "plus")
                    .font(.system(size: fabIconSize, weight: .semibold))
                    .foregroundStyle(FashColors.readableOnBrandPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: rowMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(MainNavTabButtonStyle())
        .accessibilityLabel(L10n.navPostFabCd)
    }

    private func icon(for tab: MainTab, selected: Bool) -> String {
        switch tab {
        case .home: return selected ? "house.fill" : "house"
        case .orders: return selected ? "bag.fill" : "bag"
        case .post: return "plus"
        case .chat: return selected ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right"
        case .profile: return selected ? "person.fill" : "person"
        }
    }

    private func label(for tab: MainTab) -> String {
        switch tab {
        case .home: return L10n.navHome
        case .orders: return L10n.navOrders
        case .post: return L10n.navPost
        case .chat: return L10n.navChat
        case .profile: return L10n.navProfile
        }
    }
}

/// Subtle press feedback without scaling the whole bar.
private struct MainNavTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
