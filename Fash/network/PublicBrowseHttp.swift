import Foundation

/// Guest public browse client — Android [PublicBrowseHttp].
enum PublicBrowseHttp {
    static var isConfigured: Bool {
        !AppEnvironment.publicBrowseClientId.trimmingCharacters(in: .whitespaces).isEmpty
            && !AppEnvironment.publicBrowseClientToken.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func publicApiPath(_ relativePath: String) -> String {
        AppEnvironment.apiPathWithoutLocale("api/v1/public/\(relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))")
    }

    static func applyGuestHeaders(_ request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppLocale.coreApiPathSegment(), forHTTPHeaderField: "Accept-Language")
        request.setValue(AppLocale.coreApiPathSegment(), forHTTPHeaderField: "X-Fash-Lang")
        request.setValue("Fash-iOS/1.0.3", forHTTPHeaderField: "User-Agent")
        request.setValue(AppEnvironment.publicBrowseClientId, forHTTPHeaderField: "X-Fash-Public-Client")
        request.setValue(AppEnvironment.publicBrowseClientToken, forHTTPHeaderField: "X-Fash-Public-Client-Token")
    }

    static func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var req = request
        applyGuestHeaders(&req)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}
