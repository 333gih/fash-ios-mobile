import Foundation

/// Registers the device FCM token with [AuthRepository.registerFcm] after login and on token refresh.
/// Mirrors personal-os `POSFCMRegistrar`: stash token when session is not ready, register on login.
final class FcmTokenRegistrar {
    private static let pendingTokenKey = "fash.fcm.pending_token"

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

    /// Registers stashed token after session restore/login (personal-os `registerPendingToken`).
    func registerPendingToken() async {
        guard let token = UserDefaults.standard.string(forKey: Self.pendingTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty
        else {
            return
        }
        logD("registerPendingToken: attempting stashed token")
        await registerDeviceToken(token)
    }

    func registerDeviceToken(_ token: String) async {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        PushDiagnostics.logTokenMetadata(trimmed, context: "FcmTokenRegistrar.registerDeviceToken")
        guard let session = sessionStore.read() else {
            stashPendingToken(trimmed)
            logD("registerDeviceToken: no session, stashed pending token")
            return
        }
        await registerFcmWithOptionalRefresh(session: session, token: trimmed)
    }

    static func clearPendingToken() {
        UserDefaults.standard.removeObject(forKey: pendingTokenKey)
    }

    private func stashPendingToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: Self.pendingTokenKey)
    }

    private func registerFcmWithOptionalRefresh(session: AuthSession, token: String) async {
        let locale = clientLocaleProvider()
        let first = await authRepository.registerFcm(
            accessToken: session.accessToken,
            token: token,
            clientLocale: locale
        )
        if case .success = first {
            Self.clearPendingToken()
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
            Self.clearPendingToken()
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
        PushDiagnostics.info("FcmTokenRegistrar: \(message)")
    }

    private func logW(_ message: String) {
        PushDiagnostics.warning("FcmTokenRegistrar: \(message)")
    }

    private func logE(_ message: String) {
        PushDiagnostics.error("FcmTokenRegistrar: \(message)")
    }
}
