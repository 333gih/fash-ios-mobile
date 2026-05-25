import SwiftUI

private let splashDisplaySeconds: TimeInterval = 2.5

struct RootView: View {
    @Environment(AppDependencies.self) private var deps
    @State private var router = AppRouter()
    @State private var loginVM = LoginViewModel()

    var body: some View {
        FashTheme {
            ZStack {
                rootContent
                FashGlobalDialogHost()
            }
            .fullScreenCover(item: Binding(
                get: { router.fullScreenRoute },
                set: { if $0 == nil { router.dismissFullScreen() } },
            )) { route in
                fullScreenContent(route)
            }
            .onOpenURL { url in
                DeepLinkRouter.handle(url: url, router: router, deps: deps)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(splashDisplaySeconds))
            router.showSplash = false
            await bootstrapSession()
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if router.showSplash || router.isLoggingOut {
            FashWaitingScreen()
        } else if router.isGuestMode {
            GuestMainShell(router: router)
        } else if let step = router.loginStep {
            loginFlow(step: step)
        } else if router.setupGateFetchFailed {
            SetupGateRetryScreen {
                router.setupGateFetchFailed = false
                Task { await bootstrapSession() }
            }
        } else if let onboard = router.onboardingStep {
            onboardingFlow(step: onboard)
        } else {
            MainNavScreen(router: router)
        }
    }

    @ViewBuilder
    private func fullScreenContent(_ route: FullScreenRoute) -> some View {
        switch route {
        case .listing(let id):
            ProductDetailScreen(listingId: id, onDismiss: { router.selectedListingId = nil })
        case .seller(let user):
            SellerProfileScreen(username: user, onDismiss: { router.sellerShopUsername = nil })
        case .editListing(let id):
            EditListingScreen(listingId: id, onDismiss: { router.editListingId = nil })
        case .editProfile:
            EditProfileScreen(onDismiss: { router.showEditProfile = false })
        case .chat(let id):
            ChatDetailScreen(conversationId: id, onDismiss: { router.selectedConversationId = nil })
        case .orders:
            OrdersScreen(onDismiss: { router.showOrdersScreen = false }, onSelectOrder: { router.selectedOrderId = $0 })
        case .order(let id):
            OrderDetailScreen(orderId: id, onDismiss: { router.selectedOrderId = nil })
        case .checkout(let id):
            CheckoutScreen(listingId: id, onDismiss: { router.selectedCheckoutListingId = nil })
        case .shippingAddresses:
            ShippingAddressListScreen(onDismiss: { router.showShippingAddressList = false })
        case .addAddress:
            AddEditAddressScreen(onDismiss: { router.showAddAddressScreen = false })
        case .homeEditorial(let slug):
            HomeEditorialDetailScreen(slug: slug, onDismiss: { router.homeEditorialSlug = nil })
        case .homeDelivering:
            HomeDeliveringScreen(onDismiss: { router.showHomeDeliveringScreen = false })
        case .sellerPackages:
            SellerProductPackagesScreen(onDismiss: { router.showSellerPackagesScreen = false })
        case .followConnections:
            FollowConnectionsScreen(onDismiss: { router.showFollowConnections = false })
        case .featuredSellers:
            FeaturedSellersScreen(onDismiss: { router.showFeaturedSellersAll = false })
        case .inviteFriends:
            InviteFriendsScreen(onDismiss: { router.showInviteFriendsScreen = false })
        case .changePassword:
            ChangePasswordScreen(onDismiss: { router.showChangePasswordScreen = false })
        case .editorialList:
            HomeEditorialListScreen(onDismiss: { router.showEditorialListScreen = false })
        case .uxSurvey(let key):
            UserExperienceSurveyScreen(surveyKey: key, onDismiss: { router.uxSurveyKey = nil })
        case .sellerPackageCheckout(let id):
            SellerPackageCheckoutScreen(packageId: id, onDismiss: { router.sellerPackageCheckoutId = nil })
        case .chatOrderDetail(let id):
            OrderDetailScreen(orderId: id, onDismiss: { router.chatOrderDetailOverlayId = nil })
        }
    }

    @ViewBuilder
    private func loginFlow(step: LoginStep) -> some View {
        switch step {
        case .email:
            LoginScreen(
                viewModel: loginVM,
                onOtpSent: { router.loginStep = .otp },
                onGuestBrowse: {
                    deps.isGuestBrowseActive = true
                    router.isGuestMode = true
                    router.loginStep = nil
                },
            )
        case .otp:
            OtpVerifyScreen(
                viewModel: loginVM,
                onVerified: {
                    router.loginStep = nil
                    Task { await bootstrapSession() }
                },
                onBack: { router.loginStep = .email },
            )
        }
    }

    @ViewBuilder
    private func onboardingFlow(step: OnboardingStep) -> some View {
        switch step {
        case .aestheticTags:
            OnboardingScreen(onContinue: { router.onboardingStep = .shoppingPreferences })
        case .shoppingPreferences:
            ShoppingPreferencesOnboardScreen(onContinue: { router.onboardingStep = .profilePhoto })
        case .profilePhoto:
            ProfilePhotoOnboardScreen(onContinue: { router.onboardingStep = .sizingReference })
        case .sizingReference:
            SizingReferenceScreen(onContinue: { router.onboardingStep = .username })
        case .username:
            UsernameOnboardScreen(onContinue: { router.onboardingStep = .setupPassword })
        case .setupPassword:
            SetupPasswordOnboardScreen(onContinue: { router.onboardingStep = .completed })
        case .completed:
            FashWaitingScreen()
                .task { router.onboardingStep = nil }
        }
    }

    private func bootstrapSession() async {
        router.setupGateFetchFailed = false
        if deps.authSessionStore.read() == nil {
            if PublicBrowseHttp.isConfigured {
                router.isGuestMode = true
                deps.isGuestBrowseActive = true
            } else {
                router.loginStep = .email
            }
            return
        }
        router.isGuestMode = false
        deps.isGuestBrowseActive = false
        let status = await deps.userRepository.fetchSetupStatus()
        switch status {
        case .success(let gate):
            deps.authManager.onSessionSaved()
            await deps.realtimeManager.connect()
            if gate.canAccessHome {
                router.onboardingStep = nil
                router.loginStep = nil
            } else {
                router.onboardingStep = mapNextStep(gate.nextStep)
            }
        case .failure:
            router.setupGateFetchFailed = true
        }
    }

    private func mapNextStep(_ raw: String?) -> OnboardingStep {
        switch raw {
        case "shopping_preferences": return .shoppingPreferences
        case "profile_photo": return .profilePhoto
        case "sizing_reference": return .sizingReference
        case "username": return .username
        case "setup_password": return .setupPassword
        default: return .aestheticTags
        }
    }
}
