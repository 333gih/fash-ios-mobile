import SwiftUI

struct FashInboxNotificationBellButton: View {
    var unreadCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 22))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(width: 48, height: 48)
                if unreadCount > 0 {
                    Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, unreadCount > 9 ? 4 : 5)
                        .padding(.vertical, 2)
                        .background(FashColors.brandPrimary, in: Capsule())
                        .offset(x: 4, y: 6)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.notifications)
    }
}
