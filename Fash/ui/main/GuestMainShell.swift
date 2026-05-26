import SwiftUI

struct GuestMainShell: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    @State private var showLoginSheet = false
    @State private var guestLoginReason: String?

    var body: some View {
        MainNavScreen(router: router, isGuestMode: true, onRequestSignIn: { reason in
            guestLoginReason = reason
            showLoginSheet = true
        })
        .onChange(of: router.selectedTab) { _, tab in
            if tab == .post || tab == .chat || tab == .profile {
                guestLoginReason = tabGuestReason(tab)
                showLoginSheet = true
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            GuestLoginSheet(
                onSignIn: {
                    showLoginSheet = false
                    deps.isGuestBrowseActive = false
                    router.isGuestMode = false
                    router.loginStep = .email
                },
                onContinueBrowsing: { showLoginSheet = false }
            )
        }
        .task { deps.consumePendingDeepLinks(router: router) }
    }

    private func tabGuestReason(_ tab: MainTab) -> String {
        switch tab {
        case .post: return L10n.guestLoginReasonPost
        case .chat: return L10n.guestLoginReasonChat
        case .profile: return L10n.guestLoginReasonProfile
        default: return L10n.guestLoginSheetTitle
        }
    }
}
