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
        guard let session = sessionStore.read() else {
            logD("registerDeviceToken: no session, skip")
            return
        }
        await registerFcmWithOptionalRefresh(session: session, token: token)
    }

    private func registerFcmWithOptionalRefresh(session: AuthSession, token: String) async {
        let locale = clientLocaleProvider()
        let first = await authRepository.registerFcm(
            accessToken: session.accessToken,
            token: token,
            clientLocale: locale
        )
        if case .success = first {
            logD("registerFcm: backend OK")
            return
        }
        guard case .failure(let err) = first else {
            logW("registerFcm: unknown failure")
            return
        }
        if !isUnauthorized(err) {
            logE("registerFcm: backend failed — \(err.localizedDescription)")
            return
        }
        let refreshed = await AuthTokenRefreshCoordinator.refreshIfStillCurrent(
            sessionStore: sessionStore,
            authRepository: authRepository,
            accessTokenWhenUnauthorized: session.accessToken
        )
        guard case .success(let newSession) = refreshed else {
            logW("registerFcm: access token expired; refresh failed")
            return
        }
        let second = await authRepository.registerFcm(
            accessToken: newSession.accessToken,
            token: token,
            clientLocale: locale
        )
        switch second {
        case .success:
            logD("registerFcm: backend OK after token refresh")
        case .failure(let retryErr):
            if isUnauthorized(retryErr) {
                logW("registerFcm: still 401 after refresh")
            } else {
                logE("registerFcm: failed after refresh — \(retryErr.localizedDescription)")
            }
        }
    }

    private func isUnauthorized(_ error: Error) -> Bool {
        (error as? CoreServiceHttpException)?.statusCode == 401
    }

    private func logD(_ message: String) {
        #if DEBUG
        print("[FcmTokenRegistrar] \(message)")
        #endif
    }

    private func logW(_ message: String) {
        #if DEBUG
        print("[FcmTokenRegistrar] WARN \(message)")
        #endif
    }

    private func logE(_ message: String) {
        #if DEBUG
        print("[FcmTokenRegistrar] ERROR \(message)")
        #endif
    }
}
