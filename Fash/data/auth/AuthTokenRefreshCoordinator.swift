import Foundation

enum AuthSessionMissingError: Error {
    case noStoredSession
}

/// Global refresh lock — Android [AuthTokenRefreshCoordinator].
enum AuthTokenRefreshCoordinator {
    private actor Gate {
        func refreshIfStillCurrent(
            sessionStore: AuthSessionStore,
            authRepository: AuthRepository,
            accessTokenWhenUnauthorized: String,
        ) async -> Result<AuthSession, Error> {
            guard let current = sessionStore.read() else {
                return .failure(AuthSessionMissingError.noStoredSession)
            }
            let stale = accessTokenWhenUnauthorized.trimmingCharacters(in: .whitespaces)
            if !stale.isEmpty,
               !current.accessToken.isEmpty,
               current.accessToken != stale {
                return .success(current)
            }
            let result = await authRepository.refresh(refreshToken: current.refreshToken)
            if case .success(let session) = result {
                sessionStore.save(session)
            }
            return result
        }
    }

    private static let gate = Gate()

    static func refreshIfStillCurrent(
        sessionStore: AuthSessionStore,
        authRepository: AuthRepository,
        accessTokenWhenUnauthorized: String,
    ) async -> Result<AuthSession, Error> {
        await gate.refreshIfStillCurrent(
            sessionStore: sessionStore,
            authRepository: authRepository,
            accessTokenWhenUnauthorized: accessTokenWhenUnauthorized,
        )
    }
}
