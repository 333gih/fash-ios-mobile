import Foundation

enum AuthSessionMissingError: Error {
    case noStoredSession
}

/// Global refresh singleflight — Android [AuthTokenRefreshCoordinator].
enum AuthTokenRefreshCoordinator {
    private actor Gate {
        private var inFlight: Task<Result<AuthSession, Error>, Never>?

        func refreshIfStillCurrent(
            sessionStore: AuthSessionStore,
            authRepository: AuthRepository,
            accessTokenWhenUnauthorized: String
        ) async -> Result<AuthSession, Error> {
            if let task = inFlight {
                return await task.value
            }

            guard let current = sessionStore.read() else {
                return .failure(AuthSessionMissingError.noStoredSession)
            }
            let stale = accessTokenWhenUnauthorized.trimmingCharacters(in: .whitespacesAndNewlines)
            if !stale.isEmpty,
               !current.accessToken.isEmpty,
               current.accessToken != stale {
                return .success(current)
            }

            let refreshToken = current.refreshToken
            let task = Task<Result<AuthSession, Error>, Never> {
                let result = await authRepository.refresh(refreshToken: refreshToken)
                if case .success(let session) = result {
                    sessionStore.save(session)
                }
                return result
            }
            inFlight = task
            let result = await task.value
            inFlight = nil
            return result
        }
    }

    private static let gate = Gate()

    static func refreshIfStillCurrent(
        sessionStore: AuthSessionStore,
        authRepository: AuthRepository,
        accessTokenWhenUnauthorized: String
    ) async -> Result<AuthSession, Error> {
        await gate.refreshIfStillCurrent(
            sessionStore: sessionStore,
            authRepository: authRepository,
            accessTokenWhenUnauthorized: accessTokenWhenUnauthorized
        )
    }
}
