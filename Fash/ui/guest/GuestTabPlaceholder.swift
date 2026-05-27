import SwiftUI

struct GuestTabPlaceholder: View {
    let tab: MainTab
    var onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(FashTypography.headlineMedium)
            Text(bodyText)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .multilineTextAlignment(.center)
            FashPrimaryButton(title: L10n.guestLoginSheetSignIn, action: onSignIn)
        }
        .padding(32)
    }

    private var title: String {
        switch tab {
        case .orders: return L10n.guestTabOrdersTitle
        case .post: return L10n.guestTabPostTitle
        case .chat: return L10n.guestTabChatTitle
        case .profile: return L10n.guestTabProfileTitle
        default: return L10n.guestLoginSheetTitle
        }
    }

    private var bodyText: String {
        switch tab {
        case .orders: return L10n.guestTabOrdersBody
        case .post: return L10n.guestTabPostBody
        case .chat: return L10n.guestTabChatBody
        case .profile: return L10n.guestTabProfileBody
        default: return L10n.guestLoginSheetPrivacyNote
        }
    }
}
