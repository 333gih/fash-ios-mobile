import Foundation
import Observation

struct FashInAppNotificationSession: Equatable {
    let title: String
    let body: String
    let userNotificationId: String?
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
    let browseSessionStore: BrowseSessionStore
    let addressLocalStore: AddressLocalStore
    let onboardingLocalStore: OnboardingLocalStore
    let orderCancelCoordinator: OrderCancelCoordinator
    let realtimeManager: RealtimeManager
    let fcmTokenRegistrar: FcmTokenRegistrar

    var isGuestBrowseActive = false

    // Pending deep links / signals (Android MutableStateFlow equivalents)
    var pendingDeepLinkListingId: String?
    var pendingDeepLinkSellerUsername: String?
    var pendingInboxNotificationId: String?
    var pendingReferralToken: String?
    var pendingReferrerUsername: String?
    var pendingOpenInviteFriends = false
    var inboxOpenRequestGeneration: Int = 0
    var inAppNotification: FashInAppNotificationSession?

    private init() {
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
            },
        )
        userRepository = UserRepository(client: securedClient)
        listingRepository = ListingRepository(client: securedClient)
        chatRepository = ChatRepository(client: securedClient)
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
        addressLocalStore = AddressLocalStore()
        onboardingLocalStore = OnboardingLocalStore()
        orderCancelCoordinator = OrderCancelCoordinator(orderRepository: orderRepository, chatRepository: chatRepository)
        realtimeManager = RealtimeManager(
            baseURL: AppEnvironment.realtimeBaseURL,
            sessionStore: authSessionStore,
            authRepository: authRepository,
        )
        fcmTokenRegistrar = FcmTokenRegistrar(authRepository: authRepository, sessionStore: authSessionStore)
        authManager.hydrateInitialAuthFromStore()
    }

    func handleSessionCleared(reason: String?) {
        authSessionStore.clear()
        isGuestBrowseActive = false
        realtimeManager.disconnect()
        if let reason, !reason.isEmpty {
            uiDialog.showError(reason)
        }
    }

    func consumePendingDeepLinks(router: AppRouter) {
        if let id = pendingDeepLinkListingId {
            router.selectedListingId = id
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
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencies = .shared
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
