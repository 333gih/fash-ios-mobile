import Foundation

/// Registers the device FCM token with [AuthRepository.registerFcm] after login and on token refresh.
/// Mirrors personal-os `POSFCMRegistrar`: stash token when session is not ready, register on login.
final class FcmTokenRegistrar {
    private static let pendingTokenKey = "fash.fcm.pending_token"

    private let authRepository: AuthRepository
    private let sessionStore: AuthSessionStore
    private let clientLocaleProvider: () -> String
    private let registerLock = NSLock()
    private var registerInFlight = false

    init(
        authRepository: AuthRepository,
        sessionStore: AuthSessionStore,
        clientLocaleProvider: @escaping () -> String = { AppLocale.currentTag }
    ) {
        self.authRepository = authRepository
        self.sessionStore = sessionStore
        self.clientLocaleProvider = clientLocaleProvider
    }

    /// Registers stashed FCM token after session restore/login.
    /// When Firebase Messaging is enabled, never falls back to raw APNs hex (`fash.apns.device_token`).
    func registerPendingToken() async {
        let pending = UserDefaults.standard.string(forKey: Self.pendingTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let pending, !pending.isEmpty {
            logD("registerPendingToken: attempting stashed FCM token")
            await registerDeviceToken(pending)
            return
        }
        guard !PushNotificationCoordinator.usesFirebaseMessaging else {
            return
        }
        let hex = UserDefaults.standard.string(forKey: PushNotificationCoordinator.apnsDeviceTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let hex, !hex.isEmpty else { return }
        logD("registerPendingToken: pure-APNs path, using stored device token")
        await registerDeviceToken(hex)
    }

    func registerDeviceToken(_ token: String) async {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        PushDiagnostics.logTokenMetadata(trimmed, context: "FcmTokenRegistrar.registerDeviceToken")
        if PushNotificationCoordinator.usesFirebaseMessaging, PushDiagnostics.looksLikeRawAPNSHex(trimmed) {
            PushDiagnostics.warning("FcmTokenRegistrar: rejected_raw_apns_hex — will not POST /auth/fcm/register")
            return
        }
        registerLock.lock()
        if registerInFlight {
            registerLock.unlock()
            logD("registerDeviceToken: skipped overlapping in-flight register")
            return
        }
        registerInFlight = true
        registerLock.unlock()
        defer {
            registerLock.lock()
            registerInFlight = false
            registerLock.unlock()
        }
        guard let session = sessionStore.read() else {
            if PushDiagnostics.looksLikeRawAPNSHex(trimmed), PushNotificationCoordinator.usesFirebaseMessaging {
                return
            }
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
