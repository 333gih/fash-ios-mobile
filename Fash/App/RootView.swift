import SwiftUI

private let splashDisplaySeconds: TimeInterval = 2.5

struct RootView: View {
    @Environment(AppDependencies.self) private var deps
    @State private var router = AppRouter()
    @State private var loginVM = LoginViewModel()
    @State private var addressBookVM = AddressBookViewModel()
    @State private var changePasswordVM = ChangePasswordViewModel()
    @State private var featuredSellersVM = FeaturedSellersViewModel()

    var body: some View {
        FashTheme {
            ZStack {
                rootContent
                FashGlobalDialogHost()
                if let banner = deps.inAppNotification {
                    VStack {
                        FashInAppNotificationBanner(
                            session: banner,
                            onTap: {
                                RealtimeNotificationRouter.handleInAppBannerTap(
                                    session: banner,
                                    deps: deps,
                                    router: router
                                )
                            },
                            onDismiss: { deps.dismissInAppNotification() }
                        )
                        Spacer()
                    }
                }
                if let message = deps.snackbarMessage {
                    VStack {
                        Spacer()
                        FashSnackbarHost(message: message) {
                            deps.dismissSnackbar()
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: deps.snackbarMessage)
            .fullScreenCover(item: Binding(
                get: { router.fullScreenRoute },
                set: { if $0 == nil { router.dismissFullScreen() } }
            )) { route in
                fullScreenContent(route)
            }
            .onOpenURL { url in
                if GoogleSignInClients.handle(url: url) { return }
                DeepLinkRouter.handle(url: url, router: router, deps: deps)
            }
        }
        .task {
            deps.prefetchSessionValidation()
            async let sessionValidated = deps.awaitSessionValidation()
            try? await Task.sleep(for: .seconds(splashDisplaySeconds))
            _ = await sessionValidated
            router.showSplash = false
            await bootstrapSession()
        }
        .onAppear {
            deps.navigationRouter = router
        }
        .onChange(of: deps.authManager.isAuthenticated) { _, authed in
            if authed {
                router.isGuestMode = false
                deps.isGuestBrowseActive = false
            }
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
            ProductDetailScreen(
                listingId: id,
                isGuestMode: router.isGuestMode,
                onDismiss: { router.selectedListingId = nil },
                onBuyNow: { router.selectedCheckoutListingId = $0 },
                onContinueOrder: { orderId in
                    router.selectedListingId = nil
                    router.selectedOrderId = orderId
                },
                onChat: { convId in
                    router.selectedListingId = nil
                    router.selectedConversationId = convId
                },
                onShare: { _, _ in },
                onListingClick: { listingId in
                    router.selectedListingId = listingId
                },
                onVisitSellerShop: { username in
                    router.selectedListingId = nil
                    router.sellerShopUsername = username
                },
                onRequestLogin: { router.loginStep = .email },
                onNavigateToExplore: { cat, brand, tag, query, countryId, iso in
                    router.selectedListingId = nil
                    router.pendingExploreProfileFilter = ExploreProfileFilterRequest(
                        categoryId: cat,
                        brandId: brand,
                        aestheticTagId: tag,
                        searchQuery: query,
                        countryId: countryId,
                        countryIso2: iso
                    )
                }
            )
        case .seller(let user):
            SellerProfileScreen(
                username: user,
                isGuestMode: router.isGuestMode,
                onDismiss: { router.sellerShopUsername = nil },
                onListingClick: { id in
                    router.sellerShopUsername = nil
                    deps.presentListingDetail(listingId: id, router: router)
                },
                onNavigateToExploreFromProfile: { cat, brand, tag, q, countryId, iso in
                    router.sellerShopUsername = nil
                    router.pendingExploreProfileFilter = ExploreProfileFilterRequest(
                        categoryId: cat,
                        brandId: brand,
                        aestheticTagId: tag,
                        searchQuery: q,
                        countryId: countryId,
                        countryIso2: iso
                    )
                }
            )
        case .editListing(let id):
            EditListingScreen(listingId: id, onDismiss: { router.editListingId = nil })
        case .editProfile:
            EditProfileScreen(onDismiss: { router.showEditProfile = false })
        case .chat(let id):
            ChatDetailScreen(
                conversationId: id,
                onDismiss: dismissChat,
                onProductClick: { listingId in
                    router.selectedConversationId = nil
                    deps.requestChatInboxRefresh()
                    deps.presentListingDetail(listingId: listingId, router: router)
                }
            )
        case .orders:
            OrdersScreen(onDismiss: { router.showOrdersScreen = false }, onSelectOrder: { router.selectedOrderId = $0 })
        case .order(let id):
            OrderDetailScreen(
                orderId: id,
                onDismiss: { router.selectedOrderId = nil },
                onNavigateToPayment: { listingId, _, _ in
                    router.selectedOrderId = nil
                    router.selectedCheckoutListingId = listingId
                },
                onNavigateToChat: { convId in
                    router.selectedOrderId = nil
                    router.selectedConversationId = convId
                },
                onOpenListing: { listingId, _ in
                    router.selectedOrderId = nil
                    deps.presentListingDetail(listingId: listingId, router: router)
                },
                onOpenUserProfile: { username in
                    router.selectedOrderId = nil
                    router.sellerShopUsername = username
                }
            )
        case .checkout(let id):
            CheckoutScreen(listingId: id, onDismiss: { router.selectedCheckoutListingId = nil })
        case .shippingAddresses:
            ShippingAddressListScreen(
                addressVM: addressBookVM,
                onDismiss: { router.showShippingAddressList = false },
                onAddAddress: { router.showAddAddressScreen = true }
            )
        case .addAddress:
            AddEditAddressScreen(
                addressVM: addressBookVM,
                onDismiss: { router.showAddAddressScreen = false }
            )
        case .homeEditorial(let slug):
            HomeEditorialDetailScreen(slug: slug, onDismiss: { router.homeEditorialSlug = nil })
        case .homeDelivering:
            HomeDeliveringScreen(onDismiss: { router.showHomeDeliveringScreen = false })
        case .sellerPackages:
            SellerProductPackagesScreen(
                onDismiss: { router.showSellerPackagesScreen = false },
                onBuyPackage: { pkg in router.sellerPackageCheckout = pkg }
            )
        case .followConnections:
            FollowConnectionsScreen(
                initialTab: router.followConnectionsInitialTab,
                onDismiss: { router.showFollowConnections = false },
                onUserClick: { user in
                    router.showFollowConnections = false
                    if !user.username.isEmpty {
                        router.sellerShopUsername = user.username
                    }
                }
            )
        case .featuredSellers:
            FeaturedSellersScreen(
                viewModel: featuredSellersVM,
                isGuestMode: router.isGuestMode,
                onDismiss: { router.showFeaturedSellersAll = false },
                onSellerClick: { seller in
                    router.showFeaturedSellersAll = false
                    let username = seller.username.trimmingCharacters(in: .whitespaces)
                    if !username.isEmpty {
                        router.sellerShopUsername = username
                    }
                },
                onListingClick: { listingId, _ in
                    router.showFeaturedSellersAll = false
                    deps.presentListingDetail(listingId: listingId, router: router)
                }
            )
        case .inviteFriends:
            InviteFriendsScreen(onDismiss: { router.showInviteFriendsScreen = false })
        case .changePassword:
            ChangePasswordScreen(
                viewModel: changePasswordVM,
                onDismiss: { router.showChangePasswordScreen = false }
            )
        case .editorialList:
            HomeEditorialListScreen(
                onDismiss: { router.showEditorialListScreen = false },
                onPostClick: { post in
                    let slug = post.slug.isEmpty ? post.id : post.slug
                    guard !slug.isEmpty else { return }
                    router.homeEditorialSlug = slug
                }
            )
        case .uxSurvey(let key):
            UserExperienceSurveyScreen(surveyKey: key, onDismiss: { router.uxSurveyKey = nil })
        case .sellerPackageCheckout(let pkg):
            SellerPackageCheckoutScreen(
                pkg: pkg,
                onDismiss: { router.sellerPackageCheckout = nil }
            )
        case .chatOrderDetail(let id):
            OrderDetailScreen(
                orderId: id,
                onDismiss: { router.chatOrderDetailOverlayId = nil },
                onNavigateToChat: { convId in
                    router.chatOrderDetailOverlayId = nil
                    router.selectedConversationId = convId
                },
                onOpenListing: { listingId, _ in
                    router.chatOrderDetailOverlayId = nil
                    deps.presentListingDetail(listingId: listingId, router: router)
                },
                onOpenUserProfile: { username in
                    router.chatOrderDetailOverlayId = nil
                    router.sellerShopUsername = username
                }
            )
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
                onSocialLoginVerified: {
                    router.loginStep = nil
                    Task { await bootstrapSession() }
                },
                onPasswordLoginVerified: {
                    router.loginStep = nil
                    Task { await bootstrapSession() }
                }
            )
        case .otp:
            OtpVerifyScreen(
                viewModel: loginVM,
                onVerified: {
                    router.loginStep = nil
                    Task { await bootstrapSession() }
                },
                onBack: { router.loginStep = .email }
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

    private func dismissChat() {
        router.selectedConversationId = nil
        deps.requestChatInboxRefresh()
    }

    private func bootstrapSession() async {
        router.setupGateFetchFailed = false
        let hasSession = deps.authSessionStore.read() != nil
        let sessionValid = hasSession ? await deps.revalidateSession() : false
        if !hasSession || !sessionValid {
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
            await deps.preferredLocaleSync.syncIfSession(locale: AppLocale.currentTag)
            await deps.realtimeManager.connect()
            await PushNotificationCoordinator.shared.requestAuthorizationAndRegisterForRemoteNotifications()
            await PushNotificationCoordinator.shared.registerCurrentTokenIfSession()
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
