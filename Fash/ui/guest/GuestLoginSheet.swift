import SwiftUI

struct GuestLoginSheet: View {
    var reason: String?
    var onSignIn: () -> Void
    var onContinueBrowsing: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.guestLoginSheetTitle)
                .font(FashTypography.headlineMedium)
            if let reason, !reason.isEmpty {
                Text(reason)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
            }
            Text(L10n.guestLoginSheetPrivacyNote)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            FashPrimaryButton(title: L10n.guestLoginSheetSignIn, action: onSignIn)
            Button(L10n.guestLoginSheetContinueBrowsing, action: onContinueBrowsing)
                .frame(maxWidth: .infinity)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
