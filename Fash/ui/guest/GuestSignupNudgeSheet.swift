import SwiftUI

/// Optional sign-up nudge for guests — at most once per 7 days (see guest-local-reminder.md).
struct GuestSignupNudgeSheet: View {
    let title: String?
    let bodyText: String?
    let onDismiss: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(displayTitle)
                    .font(.title2.bold())
                Text(displayBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                FashPrimaryButton(title: L10n.guestLoginSheetSignIn, action: onSignIn)
                Button(L10n.guestLoginSheetContinueBrowsing, action: onDismiss)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private var displayTitle: String {
        let t = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? L10n.guestSignupNudgeTitle : t
    }

    private var displayBody: String {
        let t = bodyText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? L10n.guestSignupNudgeBody : t
    }
}
