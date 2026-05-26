import Foundation

private let fashUserAgent = "Fash-iOS/1.0.3"
private let sessionExpiredMessage = "Session expired. Please sign in again."

/// OkHttp [SecuredApiClient] equivalent.
final class SecuredApiClient {
    private let sessionStore: AuthSessionStore
    private let authRepository: AuthRepository
    private let onSessionInvalidated: ((String?) -> Void)?
    private let session: URLSession

    init(
        sessionStore: AuthSessionStore,
        authRepository: AuthRepository,
        onSessionInvalidated: ((String?) -> Void)? = nil
    ) {
        self.sessionStore = sessionStore
        self.authRepository = authRepository
        self.onSessionInvalidated = onSessionInvalidated
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var req = authorized(request)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 401 { return (data, http) }
        if request.value(forHTTPHeaderField: "X-Fash-Retry-After-Refresh") != nil {
            sessionStore.clear()
            onSessionInvalidated?(sessionExpiredMessage)
            throw NSError(domain: "FashAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: sessionExpiredMessage])
        }
        guard sessionStore.read() != nil else {
            throw NSError(domain: "FashAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: sessionExpiredMessage])
        }
        let staleToken = sessionStore.read()?.accessToken ?? ""
        let refreshed = await AuthTokenRefreshCoordinator.refreshIfStillCurrent(
            sessionStore: sessionStore,
            authRepository: authRepository,
            accessTokenWhenUnauthorized: staleToken,
        )
        guard case .success = refreshed else {
            sessionStore.clear()
            onSessionInvalidated?(sessionExpiredMessage)
            throw NSError(domain: "FashAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: sessionExpiredMessage])
        }
        req = authorized(request)
        req.setValue("1", forHTTPHeaderField: "X-Fash-Retry-After-Refresh")
        let (data2, response2) = try await session.data(for: req)
        guard let http2 = response2 as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http2.statusCode == 401 {
            sessionStore.clear()
            onSessionInvalidated?(sessionExpiredMessage)
            throw NSError(domain: "FashAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: sessionExpiredMessage])
        }
        return (data2, http2)
    }

    private func authorized(_ request: URLRequest) -> URLRequest {
        var req = request
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(fashUserAgent, forHTTPHeaderField: "User-Agent")
        let secret = AppEnvironment.internalSecret.trimmingCharacters(in: .whitespaces)
        if !secret.isEmpty { req.setValue(secret, forHTTPHeaderField: "X-Internal-Secret") }
        if let session = sessionStore.read(), !session.accessToken.isEmpty {
            let type = session.tokenType.isEmpty ? "Bearer" : session.tokenType
            req.setValue("\(type) \(session.accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            let bearer = AppEnvironment.internalServiceBearer.trimmingCharacters(in: .whitespaces)
            if !bearer.isEmpty { req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        }
        return req
    }
}
