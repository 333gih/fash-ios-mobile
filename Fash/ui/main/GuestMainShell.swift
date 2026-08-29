import SwiftUI

struct GuestMainShell: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    @Bindable var homeVM: HomeViewModel
    @Bindable var exploreVM: ExploreViewModel
    @Bindable var profileVM: ProfileViewModel
    @Bindable var chatVM: ChatViewModel
    @Bindable var ordersVM: OrdersViewModel
    @State private var showLoginSheet = false
    @State private var showSignupNudge = false
    @State private var guestLoginReason: String?
    @State private var showPreLoginGuide = !PreLoginMascotGuideStore.hasCompleted
    @State private var preLoginAnchorFrames: [FeatureTourAnchor: CGRect] = [:]

    var body: some View {
        MainNavScreen(
            router: router,
            homeVM: homeVM,
            exploreVM: exploreVM,
            profileVM: profileVM,
            chatVM: chatVM,
            ordersVM: ordersVM,
            isGuestMode: true,
            onRequestSignIn: { reason in
            guestLoginReason = reason
            showLoginSheet = true
        },
            preLoginGuideAnchorsEnabled: showPreLoginGuide
        )
        .task {
            deps.isGuestBrowseActive = true
            GuestLocalReengagementScheduler.shared.onGuestShellEntered()
            if GuestLocalReengagementScheduler.shared.shouldShowSignupNudge() {
                try? await Task.sleep(for: .seconds(1.5))
                showSignupNudge = true
            }
            try? await Task.sleep(for: .seconds(3))
            await GuestLocalReengagementScheduler.shared.requestAuthorizationIfNeeded()
        }
        .onChange(of: router.guestPromoSignInRequested) { _, requested in
            guard requested else { return }
            router.guestPromoSignInRequested = false
            guestLoginReason = L10n.guestLoginReasonHomeForYou
            showLoginSheet = true
        }
        .task { deps.consumePendingDeepLinks(router: router) }
        .sheet(isPresented: $showLoginSheet) {
            GuestLoginSheet(
                reason: guestLoginReason,
                onSignIn: {
                    showLoginSheet = false
                    GuestLocalReengagementScheduler.shared.clearGuestState()
                    deps.isGuestBrowseActive = false
                    router.isGuestMode = false
                    router.loginStep = .email
                },
                onContinueBrowsing: { showLoginSheet = false }
            )
        }
        .onChange(of: router.pendingGuestSignupNudge) { _, pending in
            guard pending else { return }
            router.pendingGuestSignupNudge = false
            showSignupNudge = true
        }
        .sheet(isPresented: $showSignupNudge) {
            let slide = homeVM.guestReengagementSlides.first
            GuestSignupNudgeSheet(
                title: slide?.title,
                bodyText: slide?.subtitle,
                onDismiss: {
                    showSignupNudge = false
                    GuestLocalReengagementScheduler.shared.markSignupNudgeShown()
                },
                onSignIn: {
                    showSignupNudge = false
                    GuestLocalReengagementScheduler.shared.markSignupNudgeShown()
                    guestLoginReason = L10n.guestLoginReasonHomeForYou
                    showLoginSheet = true
                }
            )
        }
        .onPreferenceChange(FeatureTourAnchorKey.self) { preLoginAnchorFrames = $0 }
        .overlay {
            if showPreLoginGuide, AppWelcomeIntroStore.hasCompleted {
                PreLoginMascotGuideOverlay(
                    context: .guestShell,
                    anchorFrames: preLoginAnchorFrames
                ) {
                    showPreLoginGuide = false
                }
                .environment(\.locale, AppLocale.locale)
            }
        }
    }
}
