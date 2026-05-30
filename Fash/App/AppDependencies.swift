import Foundation
import Observation
import SwiftUI

struct FashInAppNotificationSession: Equatable {
    let title: String
    let body: String
    let userNotificationId: String?
    var dataMap: [String: String] = [:]
}

/// Application-scoped dependencies — Android [FashApplication].
@Observable
@MainActor
final class AppDependencies {
    static let shared = AppDependencies()

    let themePreference = AppThemePreference.shared
    let uiDialog = UiDialogController()
    let authSessionStore = AuthSessionStore()
    let authRepository: AuthRepository
    let authManager: AppAuthManager
    let securedClient: SecuredApiClient

    let userRepository: UserRepository
    let listingRepository: ListingRepository
    let chatRepository: ChatRepository
    let orderRepository: OrderRepository
    let searchRepository: SearchRepository
    let recommendationRepository: RecommendationRepository
    let commonCatalogRepository: CommonServiceRepository
    let publicCatalogRepository: PublicCommonCatalogRepository
    let advertisingRepository: AdvertisingRepository
    let sellerProductPackageRepository: SellerProductPackageRepository
    let appPromoInterstitialRepository: AppPromoInterstitialRepository
    let editorialGuideRepository: EditorialGuideRepository
    let dealRepository: DealRepository
    let userShippingAddressRepository: UserShippingAddressRepository
    let corePaymentRepository: CorePaymentRepository
    let uxSurveyRepository: UxSurveyRepository
    let browseSessionStore: BrowseSessionStore
    let feedEventReporter: FeedEventReporter
    let uxTabTracker: UxTabTracker
    let addressLocalStore: AddressLocalStore
    let onboardingLocalStore: OnboardingLocalStore
    let orderCancelCoordinator: OrderCancelCoordinator
    let realtimeManager: RealtimeManager
    let fcmTokenRegistrar: FcmTokenRegistrar
    let preferredLocaleSync: PreferredLocaleSync
    let listingPreview = ListingPreviewStore()

    var isGuestBrowseActive: Bool {
        get { browseSessionStore.isGuestBrowseActive }
        set { browseSessionStore.isGuestBrowseActive = newValue }
    }

    // Pending deep links / signals (Android MutableStateFlow equivalents)
    var pendingDeepLinkListingId: String?
    var pendingDeepLinkSellerUsername: String?
    var pendingInboxNotificationId: String?
    var pendingReferralToken: String?
    var pendingReferrerUsername: String?
    var pendingOpenInviteFriends = false
    var inboxOpenRequestGeneration: Int = 0
    var inboxUnreadRefreshGeneration: Int = 0
    var chatInboxRefreshGeneration: Int = 0
    var inboxUnreadCount: Int = 0
    private(set) var chatUnreadTotal: Int = 0
    private(set) var chatUnreadSnapshotGeneration: Int = 0
    private var chatUnreadByConversationId: [String: Int] = [:]
    var inAppNotification: FashInAppNotificationSession?
    var activeChatSession = ActiveChatSession()
    var snackbarMessage: String?
    var pendingAccountSwitchPrompt: AccountSwitchPrompt?

    /// Set from [RootView] so push notification taps can open overlays while the app is running.
    weak var navigationRouter: AppRouter?

    private var sessionValidationTask: Task<Bool, Never>?
    private var appPromoShowContinuation: AsyncStream<AppPromoCampaign>.Continuation?
    let appPromoShowSignals: AsyncStream<AppPromoCampaign>
    private var proactiveTokenRefreshTask: Task<Void, Never>?
    private var inboxRefreshDebounceTask: Task<Void, Never>?
    private var chatInboxRefreshDebounceTask: Task<Void, Never>?
    private var snackbarDismissTask: Task<Void, Never>?

    private init() {
        var promoContinuation: AsyncStream<AppPromoCampaign>.Continuation!
        appPromoShowSignals = AsyncStream { promoContinuation = $0 }
        appPromoShowContinuation = promoContinuation

        authRepository = AuthRepository()
        authManager = AppAuthManager(sessionStore: authSessionStore, authRepository: authRepository)
        securedClient = SecuredApiClient(
            sessionStore: authSessionStore,
            authRepository: authRepository,
            onSessionInvalidated: { reason in
                Task { @MainActor in
                    AppDependencies.shared.authManager.onSessionCleared(reason: reason)
                    AppDependencies.shared.handleSessionCleared(reason: reason)
                }
            }
        )
        userRepository = UserRepository(client: securedClient)
        listingRepository = ListingRepository(client: securedClient)
        chatRepository = ChatRepository(client: securedClient, sessionStore: authSessionStore)
        orderRepository = OrderRepository(client: securedClient)
        searchRepository = SearchRepository(client: securedClient)
        recommendationRepository = RecommendationRepository(client: securedClient)
        commonCatalogRepository = CommonServiceRepository(client: securedClient, publicCatalog: PublicCommonCatalogRepository())
        publicCatalogRepository = PublicCommonCatalogRepository()
        advertisingRepository = AdvertisingRepository(client: securedClient)
        sellerProductPackageRepository = SellerProductPackageRepository(client: securedClient)
        appPromoInterstitialRepository = AppPromoInterstitialRepository(client: securedClient)
        editorialGuideRepository = EditorialGuideRepository()
        dealRepository = DealRepository(client: securedClient)
        userShippingAddressRepository = UserShippingAddressRepository(client: securedClient)
        corePaymentRepository = CorePaymentRepository(client: securedClient)
        browseSessionStore = BrowseSessionStore()
        uxSurveyRepository = UxSurveyRepository(
            securedClient: securedClient,
            guestBrowse: { [browseSessionStore] in browseSessionStore.isGuestBrowseActive },
            guestKey: { [browseSessionStore] in browseSessionStore.guestSessionId() }
        )
        feedEventReporter = FeedEventReporter(
            repository: recommendationRepository,
            sessionIdProvider: { [authSessionStore, browseSessionStore] in
                if browseSessionStore.isGuestBrowseActive {
                    return browseSessionStore.guestSessionId()
                }
                if let uid = authSessionStore.read()?.userId, !uid.isEmpty {
                    return browseSessionStore.sessionIdForUser(uid)
                }
                return browseSessionStore.guestSessionId()
            },
            publicBrowse: { [browseSessionStore] in browseSessionStore.isGuestBrowseActive }
        )
        uxTabTracker = UxTabTracker(
            repository: recommendationRepository,
            guestBrowse: { [browseSessionStore] in browseSessionStore.isGuestBrowseActive }
        )
        addressLocalStore = AddressLocalStore()
        onboardingLocalStore = OnboardingLocalStore()
        orderCancelCoordinator = OrderCancelCoordinator(orderRepository: orderRepository, chatRepository: chatRepository)
        realtimeManager = RealtimeManager(
            baseURL: AppEnvironment.realtimeBaseURL,
            sessionStore: authSessionStore,
            authRepository: authRepository
        )
        fcmTokenRegistrar = FcmTokenRegistrar(
            authRepository: authRepository,
            sessionStore: authSessionStore,
            clientLocaleProvider: { AppLocale.coreApiPathSegment() }
        )
        preferredLocaleSync = PreferredLocaleSync(
            userRepository: userRepository,
            sessionStore: authSessionStore
        )
        AppLocaleController.shared.onLocaleChanged = { [preferredLocaleSync] tag in
            Task { await preferredLocaleSync.syncIfSession(locale: tag) }
        }
        authManager.hydrateInitialAuthFromStore()
        prefetchSessionValidation()
        startProactiveTokenRefreshLoop()
    }

    /// Starts cold-start token validation early so splash can overlap the refresh HTTP call.
    func prefetchSessionValidation() {
        guard sessionValidationTask == nil else { return }
        sessionValidationTask = Task {
            let hasSession = authSessionStore.read() != nil
            await MainActor.run { authManager.hydrateInitialAuthFromStore() }
            guard hasSession else { return false }
            return await authManager.validateOrClearSession()
        }
    }

    func awaitSessionValidation() async -> Bool {
        prefetchSessionValidation()
        return await sessionValidationTask?.value ?? false
    }

    func invalidateSessionValidationForLogin() {
        sessionValidationTask?.cancel()
        sessionValidationTask = nil
    }

    /// Fresh validation after login/logout — avoids reusing cold-start prefetch (guest shell bug).
    func revalidateSession() async -> Bool {
        sessionValidationTask?.cancel()
        sessionValidationTask = nil
        await MainActor.run { authManager.hydrateInitialAuthFromStore() }
        guard authSessionStore.read() != nil else { return false }
        let ok = await authManager.validateOrClearSession()
        sessionValidationTask = Task { ok }
        return ok
    }

    private func startProactiveTokenRefreshLoop() {
        proactiveTokenRefreshTask?.cancel()
        proactiveTokenRefreshTask = Task {
            while !Task.isCancelled {
                let waitMs = await MainActor.run { authManager.millisUntilProactiveRefresh() }
                if waitMs == Int64.max {
                    try? await Task.sleep(for: .seconds(60))
                    continue
                }
                try? await Task.sleep(for: .milliseconds(min(waitMs, 3_600_000)))
                await authManager.proactiveRefreshIfNeeded()
            }
        }
    }

    func handleSessionCleared(reason: String?) {
        uxTabTracker.closeActiveTab()
        uxTabTracker.flush()
        feedEventReporter.flush()
        feedEventReporter.clearPending()
        inboxRefreshDebounceTask?.cancel()
        chatInboxRefreshDebounceTask?.cancel()
        inboxUnreadCount = 0
        updateChatUnreadSnapshot(total: 0, perConversation: [:])
        inAppNotification = nil
        pendingAccountSwitchPrompt = nil
        AppPromoPendingQueue.clear()
        authSessionStore.clear()
        isGuestBrowseActive = false
        onboardingLocalStore.clearAll()
        realtimeManager.disconnect()
        if let reason, !reason.isEmpty {
            uiDialog.showError(reason)
        }
    }

    func consumePendingDeepLinks(router: AppRouter) {
        if let id = pendingDeepLinkListingId {
            presentListingDetail(listingId: id, router: router)
            pendingDeepLinkListingId = nil
        }
        if let user = pendingDeepLinkSellerUsername {
            router.sellerShopUsername = user
            pendingDeepLinkSellerUsername = nil
        }
        if pendingOpenInviteFriends {
            router.showInviteFriendsScreen = true
            pendingOpenInviteFriends = false
        }
        if let inboxId = pendingInboxNotificationId {
            router.showNotificationScreen = true
            router.notificationDetailId = inboxId
            pendingInboxNotificationId = nil
        }
    }

    func requestOpenNotificationInbox() {
        inboxOpenRequestGeneration += 1
    }

    /// Debounced unread badge refresh — Android inboxUnreadRefreshSignals.
    func requestInboxUnreadRefresh() {
        inboxRefreshDebounceTask?.cancel()
        inboxRefreshDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            inboxUnreadRefreshGeneration += 1
        }
    }

    /// Debounced chat inbox + nav badge refresh — Android `loadConversations` on chat back.
    func requestChatInboxRefresh() {
        chatInboxRefreshDebounceTask?.cancel()
        chatInboxRefreshDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            chatInboxRefreshGeneration += 1
        }
    }

    func updateChatUnreadSnapshot(total: Int, perConversation: [String: Int]) {
        chatUnreadTotal = total
        chatUnreadByConversationId = perConversation
        chatUnreadSnapshotGeneration += 1
    }

    func chatUnreadExcludingConversation(_ conversationId: String) -> Int {
        let cid = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return chatUnreadTotal }
        return max(0, chatUnreadTotal - (chatUnreadByConversationId[cid] ?? 0))
    }

    func showInAppNotification(_ session: FashInAppNotificationSession) {
        let openId = navigationRouter?.selectedConversationId ?? activeChatSession.conversationId
        if ChatInAppNotificationPolicy.shouldSuppressInApp(data: session.dataMap, openConversationId: openId) {
            return
        }
        inAppNotification = session
    }

    func dismissInAppNotification() {
        inAppNotification = nil
    }

    func requestShowAppPromo(_ campaign: AppPromoCampaign) {
        appPromoShowContinuation?.yield(campaign)
    }

    func requestAccountSwitchPrompt(_ prompt: AccountSwitchPrompt) {
        pendingAccountSwitchPrompt = prompt
    }

    func clearAccountSwitchPrompt() {
        pendingAccountSwitchPrompt = nil
    }

    /// Global snackbar — Android MainActivity `SerialSnackbarChannel` + VM `events`.
    func showSnackbar(_ message: String) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        snackbarDismissTask?.cancel()
        snackbarMessage = trimmed
        snackbarDismissTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            if snackbarMessage == trimmed {
                snackbarMessage = nil
            }
        }
    }

    func dismissSnackbar() {
        snackbarDismissTask?.cancel()
        snackbarMessage = nil
    }
}

private struct AppDependenciesKey: EnvironmentKey {
    @MainActor static var defaultValue: AppDependencies { AppDependencies.shared }
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
