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
    @State private var ordersVM = OrdersViewModel()
    @State private var postVM = PostViewModel()
    @State private var addressBookVM = AddressBookViewModel()
    @State private var listingPreview = ListingPreviewStore()

    private var isPostListingFlow: Bool { router.selectedTab == .post }

    var body: some View {
        VStack(spacing: 0) {
            if !isPostListingFlow {
                topBar
            }
            tabContent.frame(maxWidth: .infinity, maxHeight: .infinity)
            if !isPostListingFlow {
                bottomBar
            }
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
                        homeVM.clearCachesForSignedOutUser()
                        router.selectedTab = .home
                        await deps.authManager.logout()
                        router.showSettingsScreen = false
                        router.loginStep = .email
                    }
                },
                onLogoutAll: {
                    Task {
                        homeVM.clearCachesForSignedOutUser()
                        router.selectedTab = .home
                        await deps.authManager.logoutAll()
                        router.showSettingsScreen = false
                        router.loginStep = .email
                    }
                },
                onOpenOrders: {
                    router.showSettingsScreen = false
                    router.selectedTab = .orders
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
        .fullScreenCover(isPresented: $router.showExploreOverlay) {
            ExploreOverlayHost(
                viewModel: exploreVM,
                listingPreview: listingPreview,
                isGuestMode: isGuestMode,
                expandSearchOnAppear: router.exploreSearchExpanded,
                onClose: {
                    router.showExploreOverlay = false
                    router.exploreSearchExpanded = false
                }
            )
            .environment(\.locale, AppLocale.locale)
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
            } else {
                homeVM.onGuestBrowseEntered()
            }
        }
        .onChange(of: isGuestMode) { _, guest in
            if guest {
                homeVM.onGuestBrowseEntered()
                router.selectedTab = .home
            }
        }
        .onChange(of: deps.inboxOpenRequestGeneration) { _, _ in
            if !isGuestMode {
                router.showNotificationScreen = true
            }
        }
        .onChange(of: router.selectedTab) { _, tab in
            guard !isGuestMode else { return }
            switch tab {
            case .profile:
                Task { await profileVM.refreshIfStale(deps: deps) }
            case .chat:
                Task { await chatVM.refresh(deps: deps) }
            case .orders:
                Task { await ordersVM.refresh(deps: deps) }
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var topBar: some View {
        switch router.selectedTab {
        case .home:
            HomeTopBar(
                animateSearch: !router.featureTourActive,
                showGuestSignIn: isGuestMode,
                onSearchClick: openExploreSearch,
                onNotificationsClick: openNotifications
            )
        case .profile:
            ProfileTopBar(
                showGuestSignIn: isGuestMode,
                onSearchClick: openExploreSearch,
                onNotificationsClick: openNotifications,
                onGuestSignIn: { onRequestSignIn?(L10n.guestLoginReasonTopbar) },
                onLogout: logout,
                onOpenSettings: { router.showSettingsScreen = true },
                isLoggingOut: router.isLoggingOut
            )
        case .orders, .chat:
            MainTopBar(
                suffix: headerSuffix,
                showGuestSignIn: isGuestMode,
                onSearchClick: openExploreSearch,
                onNotificationsClick: openNotifications,
                onGuestSignIn: { onRequestSignIn?(L10n.guestLoginReasonTopbar) }
            )
        case .post:
            EmptyView()
        }
    }

    private var headerSuffix: String {
        switch router.selectedTab {
        case .home: return L10n.brandHeaderSuffixHome
        case .orders: return L10n.brandHeaderSuffixOrders
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
                isGuestMode: isGuestMode,
                onOpenExplore: { openExploreOverlay(expandSearch: false) },
                onOpenPost: { selectTab(.post) },
                onOpenOrders: { selectTab(.orders) },
                onOpenFeaturedSellersAll: { router.showFeaturedSellersAll = true },
                onFeaturedSellerClick: { seller in
                    let username = seller.username.trimmingCharacters(in: .whitespaces)
                    if !username.isEmpty {
                        router.sellerShopUsername = username
                    }
                },
                onRequestSignIn: { reason in onRequestSignIn?(reason) }
            )
        case .orders:
            if isGuestMode {
                GuestTabPlaceholder(tab: .orders, onSignIn: { onRequestSignIn?(L10n.guestLoginReasonOrders) })
            } else {
                OrdersScreen(
                    viewModel: ordersVM,
                    embeddedInMainNav: true,
                    onDismiss: {},
                    onSelectOrder: { router.selectedOrderId = $0 }
                )
            }
        case .post:
            if isGuestMode {
                GuestTabPlaceholder(tab: .post, onSignIn: { onRequestSignIn?(L10n.guestLoginReasonPost) })
            } else {
                CreateListingFlowScreen(
                    postVM: postVM,
                    addressVM: addressBookVM,
                    onClose: { router.selectedTab = .home }
                )
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
                    onOpenFollowConnections: { tab in
                        router.followConnectionsInitialTab = tab
                        router.showFollowConnections = true
                    },
                    onShippingAddressesClick: { router.showShippingAddressList = true },
                    onInviteFriendsClick: { router.showInviteFriendsScreen = true },
                    onListingClick: { id, _ in router.selectedListingId = id }
                )
            }
        }
    }

    private var bottomBar: some View {
        MainNavBottomBar(
            selectedTab: $router.selectedTab,
            chatUnreadCount: chatVM.unreadTotal,
            isPostListingFlow: isPostListingFlow,
            onTabChange: { tab in
                if isGuestMode && tab.isGuestLocked {
                    onRequestSignIn?(guestLoginReason(for: tab))
                } else {
                    router.selectedTab = tab
                }
            },
            onTabReselected: { tab in
                Task {
                    switch tab {
                    case .home:
                        await homeVM.pullToRefresh(deps: deps, isGuestMode: isGuestMode)
                    case .orders:
                        await ordersVM.pullToRefresh(deps: deps)
                    case .chat:
                        await chatVM.pullToRefresh(deps: deps)
                    case .profile:
                        await profileVM.refresh(deps: deps)
                    default:
                        break
                    }
                }
            }
        )
    }

    private func selectTab(_ tab: MainTab) {
        if isGuestMode && tab.isGuestLocked {
            onRequestSignIn?(guestLoginReason(for: tab))
        } else {
            router.selectedTab = tab
        }
    }

    private func openExploreOverlay(expandSearch: Bool) {
        router.exploreSearchExpanded = expandSearch
        router.showExploreOverlay = true
    }

    private func openExploreSearch() {
        openExploreOverlay(expandSearch: true)
    }

    private func openNotifications() {
        if isGuestMode {
            onRequestSignIn?(L10n.guestLoginReasonTopbar)
        } else {
            router.showNotificationScreen = true
        }
    }

    private func logout() {
        Task {
            homeVM.clearCachesForSignedOutUser()
            router.selectedTab = .home
            await deps.authManager.logout()
            router.loginStep = .email
        }
    }

    private func guestLoginReason(for tab: MainTab) -> String {
        switch tab {
        case .orders: return L10n.guestLoginReasonOrders
        case .post: return L10n.guestLoginReasonPost
        case .chat: return L10n.guestLoginReasonChat
        case .profile: return L10n.guestLoginReasonProfile
        default: return L10n.guestLoginSheetTitle
        }
    }
}

// MARK: - Top bars

private struct HomeTopBar: View {
    var animateSearch: Bool = true
    var showGuestSignIn: Bool = false
    let onSearchClick: () -> Void
    let onNotificationsClick: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            FashScreenTitle(suffix: L10n.brandHeaderSuffixHome)
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let progress = rememberHomeSearchExpandProgress(animate: animateSearch, date: timeline.date)
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        if progress > 0 {
                            let fieldWidth = 48 + max(geo.size.width - 48, 0) * progress
                            FashHomeHeaderSearchField(
                                onClick: onSearchClick,
                                width: fieldWidth,
                                animateHint: animateSearch && progress > 0.92,
                                contentReveal: progress
                            )
                        } else if animateSearch {
                            FashHomeCollapsedSearchIcon(onClick: onSearchClick, animateHint: true)
                        } else {
                            searchIconButton
                        }
                        if !showGuestSignIn {
                            notificationButton
                        }
                    }
                }
            }
            .frame(height: 48)
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(FashColors.surfaceContainerHighest)
    }

    private var searchIconButton: some View {
        Button(action: onSearchClick) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22))
                .foregroundStyle(FashColors.textPrimary)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.searchLabel)
    }

    private var notificationButton: some View {
        Button(action: onNotificationsClick) {
            Image(systemName: "bell")
                .font(.system(size: 22))
                .foregroundStyle(FashColors.textPrimary)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
    }
}

private struct MainTopBar: View {
    let suffix: String
    var showGuestSignIn: Bool = false
    let onSearchClick: () -> Void
    let onNotificationsClick: () -> Void
    var onGuestSignIn: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            FashScreenTitle(suffix: suffix)
            Spacer(minLength: 10)
            FashAnimatedSearchIconButton(animateHint: true, action: onSearchClick)
            if showGuestSignIn {
                Button(L10n.guestTopbarSignIn, action: onGuestSignIn)
                    .font(FashTypography.labelLarge)
            } else {
                Button(action: onNotificationsClick) {
                    Image(systemName: "bell")
                        .font(.system(size: 22))
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .background(FashColors.surfaceContainerHighest)
    }
}

private struct ProfileTopBar: View {
    var showGuestSignIn: Bool = false
    let onSearchClick: () -> Void
    let onNotificationsClick: () -> Void
    var onGuestSignIn: () -> Void = {}
    let onLogout: () -> Void
    let onOpenSettings: () -> Void
    var isLoggingOut: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            FashScreenTitle(suffix: L10n.brandHeaderSuffixProfile)
            Spacer(minLength: 10)
            FashAnimatedSearchIconButton(animateHint: true, action: onSearchClick)
            if showGuestSignIn {
                Button(L10n.guestTopbarSignIn, action: onGuestSignIn)
                    .font(FashTypography.labelLarge)
            } else {
                Button(action: onNotificationsClick) {
                    Image(systemName: "bell")
                        .font(.system(size: 22))
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                Menu {
                    Button(L10n.homeLogout, action: onLogout)
                        .disabled(isLoggingOut)
                    Button(L10n.homeSettings, action: onOpenSettings)
                        .disabled(isLoggingOut)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(width: 48, height: 48)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .background(FashColors.surfaceContainerHighest)
    }
}
