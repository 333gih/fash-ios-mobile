import Foundation

/// Registers the device FCM token with [AuthRepository.registerFcm] after login and on token refresh.
final class FcmTokenRegistrar {
    private let authRepository: AuthRepository
    private let sessionStore: AuthSessionStore
    private let clientLocaleProvider: () -> String

    init(
        authRepository: AuthRepository,
        sessionStore: AuthSessionStore,
        clientLocaleProvider: @escaping () -> String = { AppLocale.currentTag }
    ) {
        self.authRepository = authRepository
        self.sessionStore = sessionStore
        self.clientLocaleProvider = clientLocaleProvider
    }

    func registerDeviceToken(_ token: String) async {
        guard let session = sessionStore.read() else { return }
        await registerFcmWithOptionalRefresh(session: session, token: token)
    }

    private func registerFcmWithOptionalRefresh(session: AuthSession, token: String) async {
        let locale = clientLocaleProvider()
        let first = await authRepository.registerFcm(
            accessToken: session.accessToken,
            token: token,
            clientLocale: locale
        )
        if case .success = first { return }
        guard case .failure(let err) = first, isUnauthorized(err) else { return }
        let refreshed = await AuthTokenRefreshCoordinator.refreshIfStillCurrent(
            sessionStore: sessionStore,
            authRepository: authRepository,
            accessTokenWhenUnauthorized: session.accessToken
        )
        guard case .success(let newSession) = refreshed else { return }
        _ = await authRepository.registerFcm(
            accessToken: newSession.accessToken,
            token: token,
            clientLocale: locale
        )
    }

    private func isUnauthorized(_ error: Error) -> Bool {
        (error as? CoreServiceHttpException)?.statusCode == 401
    }
}
