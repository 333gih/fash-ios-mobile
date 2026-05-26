import SwiftUI

struct MainNavScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    var isGuestMode = false
    var onRequestSignIn: ((String) -> Void)? = nil

    @State private var homeVM = HomeViewModel()
    @State private var exploreVM = ExploreViewModel()
    @State private var profileVM = ProfileViewModel()
    @State private var chatVM = ChatViewModel()
    @State private var listingPreview = ListingPreviewStore()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            tabContent.frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomBar
        }
        .background(FashColors.screen)
        .sheet(item: $listingPreview.state, onDismiss: { listingPreview.close() }) { preview in
            ExploreListingPreviewSheet(
                feedItem: preview.feedItem,
                detail: preview.detail,
                isDetailLoading: preview.isDetailLoading,
                isGuestMode: isGuestMode,
                onViewDetail: {
                    router.selectedListingId = preview.feedItem.id
                    listingPreview.close()
                },
                onLike: {},
                onSave: {},
                onMessageSeller: {
                    router.selectedListingId = preview.feedItem.id
                    listingPreview.close()
                },
                onRequestLogin: {
                    onRequestSignIn?(L10n.guestLoginReasonBuy)
                }
            )
            .environment(\.locale, AppLocale.locale)
        }
        .sheet(isPresented: $router.showNotificationScreen) {
            NotificationScreen(
                userRepository: deps.userRepository,
                detailId: router.notificationDetailId,
                onDismiss: {
                    router.showNotificationScreen = false
                    router.notificationDetailId = nil
                }
            )
        }
        .sheet(isPresented: $router.showSettingsScreen) {
            SettingsScreen(
                onBack: { router.showSettingsScreen = false },
                onLogout: {
                    Task {
                        await deps.authManager.logout()
                        router.showSettingsScreen = false
                        router.loginStep = .email
                    }
                },
                onOpenOrders: {
                    router.showSettingsScreen = false
                    router.showOrdersScreen = true
                },
                onOpenAddresses: {
                    router.showSettingsScreen = false
                    router.showShippingAddressList = true
                },
                onOpenEditProfile: {
                    router.showSettingsScreen = false
                    router.showEditProfile = true
                },
                onOpenChangePassword: {
                    router.showSettingsScreen = false
                    router.showChangePasswordScreen = true
                }
            )
        }
        .overlay(alignment: .top) {
            if let banner = deps.inAppNotification {
                FashInAppNotificationBanner(session: banner) {
                    deps.inAppNotification = nil
                }
            }
        }
        .task {
            deps.consumePendingDeepLinks(router: router)
            if !isGuestMode {
                await deps.realtimeManager.connect { _ in
                    deps.requestOpenNotificationInbox()
                }
            }
        }
        .onChange(of: deps.inboxOpenRequestGeneration) { _, _ in
            router.showNotificationScreen = true
        }
        .onChange(of: router.selectedTab) { _, tab in
            guard !isGuestMode else { return }
            if tab == .profile {
                Task { await profileVM.refreshIfStale() }
            }
        }
    }

    private var topBar: some View {
        HStack {
            tabTitle
            Spacer()
            if router.selectedTab == .home {
                FashAnimatedSearchIconButton(animateHint: !router.featureTourActive) {
                    router.selectedTab = .explore
                }
            }
            if isGuestMode {
                Button(L10n.guestTopbarSignIn) {
                    onRequestSignIn?(L10n.guestLoginReasonTopbar)
                }
                .font(FashTypography.labelLarge)
            }
            Button { router.showNotificationScreen = true } label: {
                Image(systemName: "bell")
            }
            Button { router.showOrdersScreen = true } label: {
                Image(systemName: "bag")
            }
            Button { router.showSettingsScreen = true } label: {
                Image(systemName: "gearshape")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var tabTitle: some View {
        HStack(spacing: 8) {
            FashBrandMarkText()
            Text(headerSuffix).font(FashTypography.titleMedium)
        }
    }

    private var headerSuffix: String {
        switch router.selectedTab {
        case .home: return L10n.brandHeaderSuffixHome
        case .explore: return L10n.exploreTitle
        case .post: return L10n.brandHeaderSuffixPost
        case .chat: return L10n.brandHeaderSuffixChat
        case .profile: return L10n.brandHeaderSuffixProfile
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch router.selectedTab {
        case .home:
            HomeFeedContent(
                viewModel: homeVM,
                listingPreview: listingPreview,
                isGuestMode: isGuestMode
            )
                .overlay(alignment: .bottom) {
                    if AppEnvironment.shippingEnabled {
                        Button(L10n.homeDeliveringScreenTitle) {
                            router.showHomeDeliveringScreen = true
                        }
                        .font(FashTypography.labelLarge)
                        .padding(8)
                    }
                }
        case .explore:
            ExploreScreen(
                viewModel: exploreVM,
                listingPreview: listingPreview,
                isGuestMode: isGuestMode
            )
        case .post:
            if isGuestMode {
                GuestTabPlaceholder(tab: .post, onSignIn: { onRequestSignIn?(L10n.guestLoginReasonPost) })
            } else {
                CreateListingFlowScreen()
            }
        case .chat:
            if isGuestMode {
                GuestTabPlaceholder(tab: .chat, onSignIn: { onRequestSignIn?(L10n.guestLoginReasonChat) })
            } else {
                ChatScreen(viewModel: chatVM, onConversationTap: { router.selectedConversationId = $0 })
            }
        case .profile:
            if isGuestMode {
                GuestTabPlaceholder(tab: .profile, onSignIn: { onRequestSignIn?(L10n.guestLoginReasonProfile) })
            } else {
                ProfileScreen(
                    viewModel: profileVM,
                    onEditProfile: { router.showEditProfile = true },
                    onOpenSettings: { router.showSettingsScreen = true }
                )
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                Button {
                    if isGuestMode && tab.isGuestLocked {
                        onRequestSignIn?(guestLoginReason(for: tab))
                    } else {
                        router.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon(for: tab))
                        Text(label(for: tab)).font(.caption2)
                    }
                    .foregroundStyle(router.selectedTab == tab ? FashColors.brandPrimary : FashColors.textSecondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(FashColors.surfaceContainer)
    }

    private func icon(for tab: MainTab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .explore: return "safari.fill"
        case .post: return "plus.circle.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }

    private func label(for tab: MainTab) -> String {
        switch tab {
        case .home: return L10n.navHome
        case .explore: return L10n.navExplore
        case .post: return L10n.navPost
        case .chat: return L10n.navChat
        case .profile: return L10n.navProfile
        }
    }

    private func guestLoginReason(for tab: MainTab) -> String {
        switch tab {
        case .post: return L10n.guestLoginReasonPost
        case .chat: return L10n.guestLoginReasonChat
        case .profile: return L10n.guestLoginReasonProfile
        default: return L10n.guestLoginSheetTitle
        }
    }
}
