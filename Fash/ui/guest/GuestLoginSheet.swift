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

/// Presents guest login above the current stack (e.g. PDP `fullScreenCover`) — RootView-level sheets sit underneath.
struct GuestLoginSheetModifier: ViewModifier {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    @Binding var isPresented: Bool
    let reason: String?

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            GuestLoginSheet(
                reason: reason,
                onSignIn: {
                    isPresented = false
                    deps.isGuestBrowseActive = false
                    router.isGuestMode = false
                    router.loginStep = .email
                },
                onContinueBrowsing: { isPresented = false }
            )
        }
    }
}

extension View {
    func guestLoginSheet(
        isPresented: Binding<Bool>,
        reason: String?,
        router: AppRouter
    ) -> some View {
        modifier(GuestLoginSheetModifier(router: router, isPresented: isPresented, reason: reason))
    }
}
