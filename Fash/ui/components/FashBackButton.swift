import SwiftUI

/// Standard back control — mirrors Android `Icons.AutoMirrored.Filled.ArrowBack` in `TopAppBar`.
struct FashBackButton: View {
    enum Style {
        /// Scaffold overlays (Orders, Follow, PDP) — `FashColors.brandPrimary`.
        case primary
        /// Surface top bars (Explore, Chat) — `FashColors.textPrimary`.
        case navigation
    }

    var style: Style = .primary
    var badgeCount: Int = 0
    /// Chat detail uses `chat_detail_back_cd` when there is no inbox badge.
    var useChatBackLabel: Bool = false
    let action: () -> Void

    /// Leading inset when the back control sits flush to the screen edge (Material `navigationIcon`).
    static let leadingScreenInset: CGFloat = 4

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var label: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            if badgeCount > 0 {
                Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                    .font(FashTypography.labelSmall.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(FashColors.brandPrimary)
                    .clipShape(Capsule())
                    .offset(x: 6, y: -2)
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: FashColors.brandPrimary
        case .navigation: FashColors.textPrimary
        }
    }

    private var accessibilityLabel: String {
        if badgeCount > 0 {
            return L10n.chatDetailBackInboxUnreadCd(badgeCount)
        }
        if useChatBackLabel {
            return L10n.chatDetailBackCd
        }
        return L10n.cdBack
    }

    /// Label for `ToolbarItem` / `navigationBar` leading slots.
    static func toolbarLabel(style: Style = .primary) -> some View {
        Image(systemName: "chevron.left")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(style == .primary ? FashColors.brandPrimary : FashColors.textPrimary)
    }
}
