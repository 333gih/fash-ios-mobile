import SwiftUI

struct GuestMainShell: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    @Bindable var homeVM: HomeViewModel
    @Bindable var exploreVM: ExploreViewModel
    @State private var showLoginSheet = false
    @State private var guestLoginReason: String?

    var body: some View {
        MainNavScreen(
            router: router,
            homeVM: homeVM,
            exploreVM: exploreVM,
            isGuestMode: true,
            onRequestSignIn: { reason in
            guestLoginReason = reason
            showLoginSheet = true
        })
        .task { deps.consumePendingDeepLinks(router: router) }
        .sheet(isPresented: $showLoginSheet) {
            GuestLoginSheet(
                reason: guestLoginReason,
                onSignIn: {
                    showLoginSheet = false
                    deps.isGuestBrowseActive = false
                    router.isGuestMode = false
                    router.loginStep = .email
                },
                onContinueBrowsing: { showLoginSheet = false }
            )
        }
    }
}
