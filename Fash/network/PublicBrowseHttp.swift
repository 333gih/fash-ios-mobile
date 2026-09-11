import Foundation

/// Guest public browse client — Android [PublicBrowseHttp].
enum PublicBrowseHttp {
    static var isConfigured: Bool {
        !clientId.isEmpty && !clientToken.isEmpty
    }

    private static var clientId: String {
        AppEnvironment.publicBrowseClientId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static var clientToken: String {
        AppEnvironment.publicBrowseClientToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Dedicated session — no cookie jar / shared Authorization leakage into public browse.
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        config.urlCache = nil
        return URLSession(configuration: config)
    }()

    static func publicApiPath(_ relativePath: String) -> String {
        AppEnvironment.apiPathWithoutLocale("api/v1/public/\(relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))")
    }

    static func applyGuestHeaders(_ request: inout URLRequest) throws {
        guard isConfigured else {
            throw CoreServiceHttpException(
                statusCode: 503,
                message: "Public browse is not configured on this build."
            )
        }
        // Never send a user/service Bearer on public routes — Kong may treat it as JWT and 401.
        request.setValue(nil, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppLocale.coreApiPathSegment(), forHTTPHeaderField: "Accept-Language")
        request.setValue(AppLocale.coreApiPathSegment(), forHTTPHeaderField: "X-Fash-Lang")
        request.setValue("Fash-iOS/1.0.3", forHTTPHeaderField: "User-Agent")
        request.setValue(clientId, forHTTPHeaderField: "X-Fash-Public-Client")
        request.setValue(clientToken, forHTTPHeaderField: "X-Fash-Public-Client-Token")
    }

    static func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var req = request
        try applyGuestHeaders(&req)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}
