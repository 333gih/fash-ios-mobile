import Foundation

/// Guest public browse attestation (Android [PublicBrowseHttp]).
enum PublicBrowseHttp {
    static var isConfigured: Bool {
        !AppEnvironment.publicBrowseClientToken.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func publicApiPath(_ relative: String) -> String {
        let base = AppEnvironment.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let rel = relative.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(base)/\(rel)"
    }

    static func applyGuestHeaders(_ request: inout URLRequest) {
        request.setValue(AppEnvironment.publicBrowseClientId, forHTTPHeaderField: "X-Fash-Public-Client")
        request.setValue(AppEnvironment.publicBrowseClientToken, forHTTPHeaderField: "X-Fash-Public-Client-Token")
        request.setValue(AppLocale.currentTag, forHTTPHeaderField: "Accept-Language")
        request.setValue(AppLocale.currentTag, forHTTPHeaderField: "X-Fash-Lang")
    }
}
