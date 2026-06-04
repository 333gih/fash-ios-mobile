import SwiftUI

struct MainNavScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    @Bindable var homeVM: HomeViewModel
    @Bindable var exploreVM: ExploreViewModel
    @Bindable var profileVM: ProfileViewModel
    @Bindable var chatVM: ChatViewModel
    @Bindable var ordersVM: OrdersViewModel
    var isGuestMode = false
    var onRequestSignIn: ((String) -> Void)? = nil
    @State private var postVM = PostViewModel()
    @State private var addressBookVM = AddressBookViewModel()
    @State private var notificationsVM: NotificationsViewModel?
    @State private var realtimeListenerId: UUID?
    @State private var realtimePingTask: Task<Void, Never>?
    @State private var prevInboxUnreadCount = 0
    @State private var activePromoCampaign: AppPromoCampaign?
    @State private var showFeatureTour = false
    @State private var tourStep: AppTourStep = .intro
    @State private var accountSwitchPrompt: AccountSwitchPrompt?
    @State private var promoOpenCountTracked = false
    @State private var featureTourAnchorFrames: [FeatureTourAnchor: CGRect] = [:]

    private var isPostListingFlow: Bool { router.selectedTab == .post }

    var body: some View {
        MainNavScreenChrome(
            router: router,
            listingPreview: deps.listingPreview,
            isGuestMode: isGuestMode,
            isPostListingFlow: isPostListingFlow,
            onRequestSignIn: onRequestSignIn,
            onFeedEngagementPatch: { id, transform in
                homeVM.patchListingEngagement(id, transform: transform)
                exploreVM.patchListingEngagement(id, transform: transform)
            },
            topBar: { topBar },
            tabContent: { tabContent },
            bottomBar: { bottomBar }
        )
        .fullScreenCover(isPresented: $router.showNotificationScreen, onDismiss: {
            router.consumePendingNotificationNavigation(deps: deps)
            Task { await refreshInboxUnreadCount() }
        }) {
            NotificationScreen(
                userRepository: deps.userRepository,
                promoSlides: homeVM.promoSlides.map(FashPromoSlideDef.fromAdvertising),
                onPromoSlideClick: { slide, _ in router.handlePromoSlideClick(slide) },
                detailId: router.notificationDetailId,
                onDismiss: {
                    router.notificationDetailId = nil
                    router.showNotificationScreen = false
                },
                onOpenOrder: { _ in
                    router.dismissNotificationsAndNavigate(.orders)
                },
                onOpenListing: { listingId in
                    router.dismissNotificationsAndNavigate(.listing(listingId))
                },
                onOpenChat: { conversationId in
                    router.dismissNotificationsAndNavigate(.chat(conversationId))
                },
                onOpenFollowConnections: { tab in
                    router.dismissNotificationsAndNavigate(.followConnections(tab))
                },
                onOpenExplore: {
                    router.dismissNotificationsAndNavigate(.explore)
                },
                onOpenInviteFriends: {
                    router.dismissNotificationsAndNavigate(.inviteFriends)
                }
            )
            .environment(\.locale, AppLocale.locale)
            .fashInAppNotificationOverlay()
        }
        .sheet(isPresented: $router.showSettingsScreen) {
            SettingsScreen(
                onBack: { router.showSettingsScreen = false },
                onLogout: {
                    Task {
                        homeVM.clearCachesForSignedOutUser(deps: deps)
                        profileVM.clearCachedProfile(deps: deps)
                        chatVM.clearCachesForSignedOutUser()
                        router.selectedTab = .home
                        await deps.authManager.logout()
                        router.showSettingsScreen = false
                        router.loginStep = .email
                    }
                },
                onLogoutAll: {
                    Task {
                        homeVM.clearCachesForSignedOutUser(deps: deps)
                        profileVM.clearCachedProfile(deps: deps)
                        chatVM.clearCachesForSignedOutUser()
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
                },
                onOpenNotificationPreferences: {
                    router.showSettingsScreen = false
                    router.showNotificationPreferencesScreen = true
                }
            )
        }
        .overlay(alignment: .bottom) {
            if let message = deps.snackbarMessage {
                FashSnackbarHost(message: message) {
                    deps.dismissSnackbar()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            FashAppPromoOverlayHost(
                campaign: activePromoCampaign,
                onDismiss: dismissActivePromo,
                onPrimaryClick: handlePromoPrimary,
                onSecondaryClick: handlePromoSecondary
            )
        }
        .overlay {
            if showFeatureTour {
                AppFeatureTourOverlay(
                    currentStep: tourStep,
                    anchorFrames: featureTourAnchorFrames,
                    onStepChange: { step in
                        tourStep = step
                        if let tab = step.prepareTab {
                            router.selectedTab = tab
                        }
                    },
                    onSkip: finishFeatureTour,
                    onFinish: finishFeatureTour
                )
            }
        }
        .onPreferenceChange(FeatureTourAnchorKey.self) { featureTourAnchorFrames = $0 }
        .animation(.easeInOut(duration: 0.22), value: deps.snackbarMessage)
        .fashInAppNotificationOverlay()
        .animation(.easeInOut(duration: 0.25), value: activePromoCampaign?.campaignId)
        .fashEdgeBackNavigation(
            router: router,
            notificationsViewModel: notificationsVM,
            isEnabled: router.listingDetailPath.isEmpty
        )
        .task(id: isGuestMode) {
            guard !isGuestMode else {
                activePromoCampaign = nil
                return
            }
            for await promo in deps.appPromoShowSignals {
                AppPromoPresenter.presentAdminPromoIfEligible(
                    promo,
                    active: &activePromoCampaign,
                    isGuestMode: isGuestMode,
                    selectedConversationId: router.selectedConversationId
                )
            }
        }
        .task(id: "promoOnAppOpen-\(isGuestMode)") {
            guard !isGuestMode else { return }
            await tryPresentAppOpenPromo(incrementOpenCount: true)
        }
        .task(id: "featureTour-\(isGuestMode)") {
            guard !isGuestMode else {
                showFeatureTour = false
                router.featureTourActive = false
                return
            }
            guard !AppFeatureTourStore.isCompletedForCurrentVersion() else { return }
            try? await Task.sleep(for: .milliseconds(400))
            guard activePromoCampaign == nil else { return }
            showFeatureTour = true
            router.featureTourActive = true
            tourStep = .intro
            router.selectedTab = .home
        }
        .onChange(of: activePromoCampaign?.campaignId) { _, newId in
            if newId != nil {
                showFeatureTour = false
                router.featureTourActive = false
            }
        }
        .onChange(of: deps.appPromoCatalogRefreshGeneration) { _, _ in
            guard !isGuestMode, activePromoCampaign == nil, router.selectedConversationId == nil else { return }
            Task {
                await AppPromoOnAppOpenLoader.fetchAndEnqueue(deps: deps)
                if let promo = AppPromoOnAppOpenLoader.resolvePresentable(),
                   !AppPromoCampaignStore.isDialogConsumed(promo) {
                    activePromoCampaign = promo
                    AppPromoCampaignStore.recordShow(promo)
                    AppPromoCampaignStore.markDialogConsumed(promo)
                    AppPromoPendingQueue.remove(campaignId: promo.campaignId)
                    AppPromoPresentationPolicy.markInboxReadAfterDialogShown(
                        campaign: promo,
                        userRepository: deps.userRepository
                    )
                }
            }
        }
        .onChange(of: router.selectedConversationId) { _, conversationId in
            if conversationId != nil {
                activePromoCampaign = nil
            } else {
                guard !isGuestMode else { return }
                Task {
                    await chatVM.loadConversationsWhenNeeded(deps: deps, staleAfterMs: 0)
                    await chatVM.refreshUnreadCount(deps: deps)
                }
            }
        }
        .onChange(of: deps.chatInboxRefreshGeneration) { _, _ in
            guard !isGuestMode else { return }
            Task {
                await chatVM.silentRefresh(deps: deps)
                await chatVM.refreshUnreadCount(deps: deps)
            }
        }
        .onChange(of: deps.pendingAccountSwitchPrompt) { _, prompt in
            accountSwitchPrompt = prompt
        }
        .alert(
            L10n.accountSwitchDialogTitle,
            isPresented: Binding(
                get: { accountSwitchPrompt != nil },
                set: { if !$0 { deps.clearAccountSwitchPrompt(); accountSwitchPrompt = nil } }
            ),
            presenting: accountSwitchPrompt
        ) { prompt in
            Button(L10n.accountSwitchDialogConfirm) {
                Task {
                    deps.clearAccountSwitchPrompt()
                    accountSwitchPrompt = nil
                    await deps.authManager.logout()
                    router.loginStep = .email
                }
            }
            Button(L10n.accountSwitchDialogDismiss, role: .cancel) {
                deps.clearAccountSwitchPrompt()
                accountSwitchPrompt = nil
            }
        } message: { prompt in
            Text(L10n.accountSwitchDialogMessage(prompt.emailMasked ?? "…", prompt.unreadCount))
        }
        .task {
            deps.consumePendingDeepLinks(router: router)
            if notificationsVM == nil {
                notificationsVM = NotificationsViewModel(userRepository: deps.userRepository)
            }
            if !isGuestMode {
                async let inbox: Void = refreshInboxUnreadCount()
                async let chatUnread: Void = chatVM.refreshUnreadCount(deps: deps)
                _ = await (inbox, chatUnread)
                startRealtimeServices()
            } else {
                stopRealtimeServices()
                homeVM.onGuestBrowseEntered(deps: deps)
            }
        }
        .task(id: "chat-unread-hub-\(isGuestMode)") {
            guard !isGuestMode else { return }
            for await _ in ChatUnreadRefreshHub.signals {
                await chatVM.silentRefresh(deps: deps)
                await chatVM.refreshUnreadCount(deps: deps)
            }
        }
        .onChange(of: isGuestMode) { _, guest in
            if guest {
                activePromoCampaign = nil
                stopRealtimeServices()
                homeVM.onGuestBrowseEntered(deps: deps)
                router.selectedTab = .home
            } else {
                Task {
                    async let inbox: Void = refreshInboxUnreadCount()
                    async let chatUnread: Void = chatVM.refreshUnreadCount(deps: deps)
                    _ = await (inbox, chatUnread)
                    startRealtimeServices()
                }
            }
        }
        .onChange(of: deps.inboxUnreadRefreshGeneration) { _, _ in
            Task {
                let before = prevInboxUnreadCount
                await refreshInboxUnreadCount()
                let after = deps.inboxUnreadCount
                prevInboxUnreadCount = after
                if after > before, deps.inAppNotification == nil, !isGuestMode {
                    deps.showInAppNotification(FashInAppNotificationSession(
                        title: L10n.notifications,
                        body: L10n.notificationNewArrivalSnackbar,
                        userNotificationId: nil,
                        dataMap: [:]
                    ))
                }
            }
        }
        .onChange(of: deps.inboxOpenRequestGeneration) { _, _ in
            if !isGuestMode {
                router.showNotificationScreen = true
            }
        }
        .onChange(of: router.pendingExploreProfileFilter) { _, _ in
            Task { await applyPendingExploreProfileFilter() }
        }
        .onChange(of: router.showEditProfile) { wasOpen, isOpen in
            if wasOpen, !isOpen, !isGuestMode {
                homeVM.refreshSizingBannerAfterProfileSave(deps: deps, isGuestMode: isGuestMode)
            }
        }
        .onChange(of: router.selectedTab) { _, tab in
            guard !isGuestMode else { return }
            switch tab {
            case .home:
                homeVM.ensureSelectedFeedTabLoaded(deps: deps, isGuestMode: isGuestMode)
            case .profile:
                Task { await profileVM.refreshIfStale(deps: deps) }
            case .chat:
                Task {
                    await chatVM.refresh(deps: deps)
                    await chatVM.resyncConversationSubscriptions(deps: deps)
                }
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
                unreadCount: deps.inboxUnreadCount,
                featureTourAnchorsEnabled: showFeatureTour,
                onSearchClick: openExploreSearch,
                onNotificationsClick: openNotifications
            )
        case .profile:
            ProfileTopBar(
                showGuestSignIn: isGuestMode,
                unreadCount: deps.inboxUnreadCount,
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
                unreadCount: deps.inboxUnreadCount,
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
                router: router,
                isGuestMode: isGuestMode,
                onOpenExplore: { openExploreOverlay(expandSearch: false) },
                onOpenFeaturedSellersAll: { router.showFeaturedSellersAll = true },
                onFeaturedSellerClick: { seller in
                    let username = seller.username.trimmingCharacters(in: .whitespaces)
                    guard !username.isEmpty else { return }
                    deps.openSellerShop(username: username, router: router)
                },
                onRequestSignIn: { reason in onRequestSignIn?(reason) },
                onOpenSizingSetup: isGuestMode ? nil : { router.showEditProfile = true },
                onDeliveringJourneyClick: {
                    Task {
                        await ordersVM.openBuyingInTransit(deps: deps)
                        selectTab(.orders)
                    }
                },
                onSavedJourneyClick: {
                    profileVM.requestWishlistTabFromHome(deps: deps)
                    selectTab(.profile)
                },
                onInReviewJourneyClick: {
                    profileVM.requestInReviewTabFromHome(deps: deps)
                    selectTab(.profile)
                },
                onExploreShortcutClick: { shortcut in
                    router.pendingExploreProfileFilter = ExploreProfileFilterRequest(
                        categoryId: shortcut.categoryId,
                        brandId: shortcut.brandId,
                        aestheticTagId: shortcut.aestheticTagId,
                        searchQuery: "",
                        countryId: nil,
                        countryIso2: nil
                    )
                }
            )
        case .orders:
            if isGuestMode {
                GuestTabPlaceholder(tab: .orders, onSignIn: { onRequestSignIn?(L10n.guestLoginReasonOrders) })
            } else {
                OrdersScreen(
                    viewModel: ordersVM,
                    embeddedInMainNav: true,
                    promoSlides: homeVM.promoSlides.map(FashPromoSlideDef.fromAdvertising),
                    onPromoSlideClick: { slide, _ in router.handlePromoSlideClick(slide) },
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
                ChatScreen(
                    viewModel: chatVM,
                    promoSlides: homeVM.promoSlides.map(FashPromoSlideDef.fromAdvertising),
                    onPromoSlideClick: { slide, _ in router.handlePromoSlideClick(slide) },
                    onConversationTap: { router.selectedConversationId = $0 }
                )
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
                    onListingClick: { id, _ in deps.presentListingDetail(listingId: id, router: router) },
                    onEditListingClick: { id in
                        router.selectedListingId = nil
                        deps.listingPreview.close(deps: deps)
                        router.profileEditReturn = ProfileEditReturnContext(
                            tab: profileVM.lastSelectedProfileTab,
                            listingId: id
                        )
                        router.editListingId = id
                    },
                    onNavigateToExploreFromProfile: { cat, brand, tag, q, countryId, iso in
                        deps.openExploreFromProfileChips(
                            router: router,
                            exploreVM: exploreVM,
                            categoryId: cat,
                            brandId: brand,
                            aestheticTagId: tag,
                            searchQuery: q,
                            countryId: countryId,
                            countryIso2: iso
                        )
                    }
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
                        homeVM.requestScrollHomeToTop()
                        await homeVM.pullToRefresh(deps: deps, isGuestMode: isGuestMode)
                    case .orders:
                        ordersVM.requestScrollOrdersToTop()
                        await ordersVM.pullToRefresh(deps: deps)
                    case .chat:
                        chatVM.requestScrollChatToTop()
                        await chatVM.pullToRefresh(deps: deps)
                    case .profile:
                        profileVM.requestScrollProfileToTop()
                        await profileVM.refresh(deps: deps)
                    case .post:
                        await postVM.reloadOnNavReselect(deps: deps)
                    }
                }
            },
            isTabNavLoading: { tab in
                guard router.selectedTab == tab else { return false }
                switch tab {
                case .home: return homeVM.isRefreshing
                case .orders: return ordersVM.isRefreshing || ordersVM.isLoading
                case .chat: return chatVM.isRefreshing
                case .profile: return profileVM.isRefreshing || profileVM.isLoading
                case .post: return postVM.navReselectLoading
                }
            },
            featureTourAnchorsEnabled: showFeatureTour
        )
    }

    private func selectTab(_ tab: MainTab) {
        if isGuestMode && tab.isGuestLocked {
            onRequestSignIn?(guestLoginReason(for: tab))
        } else {
            router.selectedTab = tab
        }
    }

    private func tryPresentAppOpenPromo(incrementOpenCount: Bool) async {
        guard !isGuestMode, activePromoCampaign == nil, router.selectedConversationId == nil else { return }
        try? await Task.sleep(for: .milliseconds(550))
        guard activePromoCampaign == nil, router.selectedConversationId == nil else { return }
        if incrementOpenCount {
            promoOpenCountTracked = true
        }
        if let promo = await AppPromoOnAppOpenLoader.syncAndResolve(
            deps: deps,
            isGuestMode: isGuestMode,
            blockBecauseOtherUi: false,
            incrementOpenCount: incrementOpenCount
        ), !AppPromoCampaignStore.isDialogConsumed(promo) {
            activePromoCampaign = promo
            AppPromoCampaignStore.recordShow(promo)
            AppPromoCampaignStore.markDialogConsumed(promo)
            AppPromoPendingQueue.remove(campaignId: promo.campaignId)
            AppPromoPresentationPolicy.markInboxReadAfterDialogShown(
                campaign: promo,
                userRepository: deps.userRepository
            )
            return
        }
    }

    private func finishFeatureTour() {
        AppFeatureTourStore.markCompletedForCurrentVersion()
        showFeatureTour = false
        router.featureTourActive = false
    }

    private func dismissActivePromo() {
        if let campaign = activePromoCampaign {
            AppPromoCampaignStore.markDismissed(campaign)
            AppPromoPresentationPolicy.markInboxReadAfterDialogShown(
                campaign: campaign,
                userRepository: deps.userRepository
            )
        }
        activePromoCampaign = nil
    }

    private func handlePromoPrimary(_ campaign: AppPromoCampaign) {
        AppPromoCampaignStore.markDismissed(campaign)
        AppPromoPresentationPolicy.markInboxReadAfterDialogShown(
            campaign: campaign,
            userRepository: deps.userRepository
        )
        activePromoCampaign = nil
        AppPromoNavigation.applyPrimary(campaign: campaign, router: router)
    }

    private func handlePromoSecondary(_ campaign: AppPromoCampaign) {
        if campaign.isRemote {
            AppPromoNavigation.applySecondary(campaign: campaign, router: router)
        } else {
            AppPromoCampaignStore.markDismissed(campaign)
        }
        AppPromoPresentationPolicy.markInboxReadAfterDialogShown(
            campaign: campaign,
            userRepository: deps.userRepository
        )
        activePromoCampaign = nil
    }

    private func refreshInboxUnreadCount() async {
        if notificationsVM == nil {
            notificationsVM = NotificationsViewModel(userRepository: deps.userRepository)
        }
        await notificationsVM?.refreshUnreadSummary()
        deps.inboxUnreadCount = notificationsVM?.unreadCount ?? 0
        if prevInboxUnreadCount == 0 {
            prevInboxUnreadCount = deps.inboxUnreadCount
        }
    }

    private func startRealtimeServices() {
        guard !isGuestMode else { return }
        stopRealtimeServices()
        realtimeListenerId = deps.realtimeManager.addEventListener { event in
            guard let notificationsVM else { return }
            RealtimeNotificationRouter.handle(
                event,
                deps: deps,
                router: router,
                notificationsVM: notificationsVM,
                chatVM: chatVM,
                homeVM: homeVM,
                exploreVM: exploreVM,
                isGuestMode: isGuestMode
            )
        }
        realtimePingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                deps.realtimeManager.sendPing()
            }
        }
        Task { await deps.realtimeManager.connect() }
    }

    private func stopRealtimeServices() {
        if let id = realtimeListenerId {
            deps.realtimeManager.removeEventListener(id)
            realtimeListenerId = nil
        }
        realtimePingTask?.cancel()
        realtimePingTask = nil
    }

    private func openExploreOverlay(expandSearch: Bool) {
        deps.listingPreview.close(deps: deps)
        router.exploreSearchExpanded = expandSearch
        router.showExploreOverlay = true
    }

    private func applyPendingExploreProfileFilter() async {
        guard let raw = router.pendingExploreProfileFilter else { return }
        router.pendingExploreProfileFilter = nil
        let req = ExploreProfileFilterRequest.forProfileNavigation(
            categoryId: raw.categoryId,
            brandId: raw.brandId,
            aestheticTagId: raw.aestheticTagId,
            searchQuery: raw.searchQuery,
            countryId: raw.countryId,
            countryIso2: raw.countryIso2
        )
        await exploreVM.openFromProfileFilter(
            deps: deps,
            categoryId: req.categoryId,
            brandId: req.brandId,
            aestheticTagId: req.aestheticTagId,
            searchQuery: req.searchQuery,
            countryId: req.countryId,
            countryIso2: req.countryIso2
        )
        openExploreOverlay(expandSearch: false)
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
            homeVM.clearCachesForSignedOutUser(deps: deps)
            chatVM.clearCachesForSignedOutUser()
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

/// Hosts main chrome + listing preview sheet with a valid `@Bindable` projection.
private struct MainNavScreenChrome<TopBar: View, TabContent: View, BottomBar: View>: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    @Bindable var listingPreview: ListingPreviewStore
    var isGuestMode: Bool
    var isPostListingFlow: Bool
    var onRequestSignIn: ((String) -> Void)?
    var onFeedEngagementPatch: ((String, (ListingFeedItem) -> ListingFeedItem) -> Void)? = nil
    @ViewBuilder var topBar: () -> TopBar
    @ViewBuilder var tabContent: () -> TabContent
    @ViewBuilder var bottomBar: () -> BottomBar

    var body: some View {
        VStack(spacing: 0) {
            if !isPostListingFlow {
                topBar()
            }
            tabContent().frame(maxWidth: .infinity, maxHeight: .infinity)
            if !isPostListingFlow {
                bottomBar()
            }
        }
        .background(FashColors.screen)
        .overlay(alignment: .bottom) {
            if !router.showExploreOverlay {
                ListingPreviewOverlay(
                    listingPreview: listingPreview,
                    router: router,
                    isGuestMode: isGuestMode,
                    onRequestLogin: { onRequestSignIn?(L10n.guestLoginReasonBuy) },
                    onFeedEngagementPatch: onFeedEngagementPatch
                )
            }
        }
    }
}

// MARK: - Top bars

private struct HomeTopBar: View {
    var animateSearch: Bool = true
    var showGuestSignIn: Bool = false
    var unreadCount: Int = 0
    var featureTourAnchorsEnabled: Bool = false
    let onSearchClick: () -> Void
    let onNotificationsClick: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            FashScreenTitle(suffix: L10n.brandHeaderSuffixHome)
            HStack(spacing: 0) {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let progress = rememberHomeSearchExpandProgress(animate: animateSearch, date: timeline.date)
                    GeometryReader { geo in
                        let fieldWidth = 48 + max(geo.size.width - 48, 0) * progress
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            if progress > 0 {
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
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                if !showGuestSignIn {
                    notificationButton
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(FashColors.surface)
        .featureTourAnchor(.topActionsRow, enabled: featureTourAnchorsEnabled)
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
        FashInboxNotificationBellButton(unreadCount: unreadCount, action: onNotificationsClick)
    }
}

private struct MainTopBar: View {
    let suffix: String
    var showGuestSignIn: Bool = false
    var unreadCount: Int = 0
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
                FashInboxNotificationBellButton(unreadCount: unreadCount, action: onNotificationsClick)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .background(FashColors.surface)
    }
}

private struct ProfileTopBar: View {
    var showGuestSignIn: Bool = false
    var unreadCount: Int = 0
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
                FashInboxNotificationBellButton(unreadCount: unreadCount, action: onNotificationsClick)
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
        .background(FashColors.surface)
    }
}
