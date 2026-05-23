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

    func logout() async {
        if let session = sessionStore.read() {
            _ = await authRepository.logout(accessToken: session.accessToken)
        }
        sessionStore.clear()
        onSessionCleared()
    }

    func logoutAll() async {
        if let session = sessionStore.read() {
            _ = await authRepository.logoutAll(accessToken: session.accessToken)
        }
        sessionStore.clear()
        onSessionCleared()
    }
}
