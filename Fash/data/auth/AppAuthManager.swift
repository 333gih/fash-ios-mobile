import Foundation
import Observation

/// Central auth state — Android [AppAuthManager].
@Observable
@MainActor
final class AppAuthManager {
    let sessionStore: AuthSessionStore
    let authRepository: AuthRepository

    var isAuthenticated = false
    var sessionExpiredMessage: String?

    init(sessionStore: AuthSessionStore, authRepository: AuthRepository) {
        self.sessionStore = sessionStore
        self.authRepository = authRepository
    }

    func hydrateInitialAuthFromStore() {
        isAuthenticated = sessionStore.read() != nil
    }

    func onSessionSaved() {
        isAuthenticated = true
        Task {
            await PushNotificationCoordinator.shared.requestAuthorizationAndRegisterForRemoteNotifications()
            await PushNotificationCoordinator.shared.registerCurrentTokenIfSession()
        }
    }

    func onSessionCleared(reason: String? = nil) {
        if let reason, !reason.isEmpty {
            sessionExpiredMessage = reason
        }
        isAuthenticated = false
    }

    func clearSessionExpiredMessage() {
        sessionExpiredMessage = nil
    }

    /**
     * Cold-start validation: refresh when the access token is likely expired.
     * Skips the network when still within [accessTokenRefreshSkewMs] of expiry.
     */
    func validateOrClearSession() async -> Bool {
        guard let session = sessionStore.read() else { return false }
        if isAccessTokenLikelyValid(session) {
            isAuthenticated = true
            return true
        }
        for attempt in 0..<Self.refreshAttempts {
            guard let snapshot = sessionStore.read() else { return false }
            let result = await AuthTokenRefreshCoordinator.refreshIfStillCurrent(
                sessionStore: sessionStore,
                authRepository: authRepository,
                accessTokenWhenUnauthorized: snapshot.accessToken
            )
            if case .success = result {
                onSessionSaved()
                return true
            }
            if case .failure(let err) = result {
                if AuthRefreshPolicy.isTransientRefreshFailure(err) {
                    if attempt < Self.refreshAttempts - 1 {
                        try? await Task.sleep(for: .milliseconds(400 * (attempt + 1)))
                        continue
                    }
                    isAuthenticated = sessionStore.read() != nil
                    return true
                }
                sessionStore.clear()
                isAuthenticated = false
                return false
            }
        }
        return true
    }

    /// Milliseconds until proactive refresh; `Int64.max` when logged out.
    func millisUntilProactiveRefresh() -> Int64 {
        guard let session = sessionStore.read() else { return Int64.max }
        if session.expiresInSeconds <= 0 { return 60_000 }
        let issued = sessionStore.issuedAtMillis()
        if issued <= 0 { return 60_000 }
        let refreshAt = issued + session.expiresInSeconds * 1000 - Self.accessTokenRefreshSkewMs
        return max(30_000, refreshAt - Int64(Date().timeIntervalSince1970 * 1000))
    }

    /** Background refresh before JWT expiry — avoids 401 → refresh → retry on API calls. */
    func proactiveRefreshIfNeeded() async {
        guard let session = sessionStore.read() else { return }
        if isAccessTokenLikelyValid(session) { return }
        let result = await AuthTokenRefreshCoordinator.refreshIfStillCurrent(
            sessionStore: sessionStore,
            authRepository: authRepository,
            accessTokenWhenUnauthorized: session.accessToken
        )
        if case .success = result {
            onSessionSaved()
        }
    }

    func logout() async {
        let session = sessionStore.read()
        let userId = session?.userId
        if let session {
            _ = await authRepository.logout(accessToken: session.accessToken)
        }
        sessionStore.clear()
        UxPersonalizationLocalStore.clearForUser(userId: userId)
        SocialAuthCacheClear.clearCachedSocialSignInForLogout()
        onSessionCleared()
    }

    func logoutAll() async {
        let session = sessionStore.read()
        let userId = session?.userId
        if let session {
            _ = await authRepository.logoutAll(accessToken: session.accessToken)
        }
        sessionStore.clear()
        UxPersonalizationLocalStore.clearForUser(userId: userId)
        SocialAuthCacheClear.clearCachedSocialSignInForLogout()
        onSessionCleared()
    }

    private func isAccessTokenLikelyValid(_ session: AuthSession) -> Bool {
        if session.expiresInSeconds <= 0 { return false }
        let issued = sessionStore.issuedAtMillis()
        if issued <= 0 { return false }
        let expMs = issued + session.expiresInSeconds * 1000
        return Int64(Date().timeIntervalSince1970 * 1000) < expMs - Self.accessTokenRefreshSkewMs
    }

    private static let refreshAttempts = 3
    private static let accessTokenRefreshSkewMs: Int64 = 60_000
}
