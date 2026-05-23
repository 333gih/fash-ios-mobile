import Foundation
import Observation
import SwiftUI

/// Application-scoped dependencies (Android [FashApplication]).
@Observable
@MainActor
final class AppDependencies {
    static let shared = AppDependencies()

    let themePreference = AppThemePreference()
    let uiDialog = UiDialogController()
    let authSessionStore = AuthSessionStore()
    let authRepository: AuthRepository
    let userRepository: UserRepository
    let listingRepository: ListingRepository
    let chatRepository: ChatRepository
    let orderRepository: OrderRepository
    let searchRepository: SearchRepository
    let recommendationRepository: RecommendationRepository
    let commonCatalogRepository: CommonServiceRepository
    let publicCatalogRepository: PublicCommonCatalogRepository
    let securedClient: SecuredApiClient
    let realtimeManager: RealtimeManager

    var isGuestBrowseActive = false
    var pendingDeepLinkListingId: String?
    var pendingDeepLinkSellerUsername: String?
    var pendingInboxNotificationId: String?
    var pendingOpenInviteFriends = false

    private init() {
        authRepository = AuthRepository()
        securedClient = SecuredApiClient(
            sessionStore: authSessionStore,
            authRepository: authRepository,
            onSessionInvalidated: { reason in
                Task { @MainActor in
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
        commonCatalogRepository = CommonServiceRepository()
        publicCatalogRepository = PublicCommonCatalogRepository()
        realtimeManager = RealtimeManager(
            baseURL: AppEnvironment.realtimeBaseURL,
            sessionStore: authSessionStore,
            authRepository: authRepository,
        )
    }

    func handleSessionCleared(reason: String?) {
        authSessionStore.clear()
        isGuestBrowseActive = false
        if let reason, !reason.isEmpty {
            uiDialog.showError(reason)
        }
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
