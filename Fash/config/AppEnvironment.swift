import Foundation

/// Typed access to build config (Android [AppEnvironment] / BuildConfig).
enum AppEnvironment {
    static var environmentName: String { BuildConfig.environmentName }
    static var flavor: String { BuildConfig.flavor }
    static var isDev: Bool { flavor == "dev" }
    static var authServiceBaseURL: String { BuildConfig.authServiceBaseURL }
    static var apiBaseURL: String { BuildConfig.apiBaseURL }
    static var commonServiceBaseURL: String { BuildConfig.commonServiceBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
    static var realtimeBaseURL: String {
        let explicit = BuildConfig.realtimeBaseURL.trimmingCharacters(in: .whitespaces)
        if !explicit.isEmpty { return explicit }
        let api = apiBaseURL
        if api.contains("api-core.") {
            return api.replacingOccurrences(of: "api-core.", with: "api-realtime.")
        }
        return api
    }
    static var authClientId: String { BuildConfig.authClientId }
    static var internalSecret: String { BuildConfig.internalSecret }
    static var internalServiceBearer: String { BuildConfig.internalServiceBearer }
    static var coreApiUseLanguagePrefix: Bool { BuildConfig.coreApiUseLanguagePrefix }
    static var authApiUseLanguagePrefix: Bool { BuildConfig.authApiUseLanguagePrefix }
    static var googleWebClientId: String { BuildConfig.googleWebClientId }
    static var listingShareBaseURL: String { BuildConfig.listingShareBaseURL }
    static var legalPortalBaseURL: String { BuildConfig.legalPortalBaseURL }
    static var publicBrowseClientId: String { BuildConfig.publicBrowseClientId }
    static var publicBrowseClientToken: String { BuildConfig.publicBrowseClientToken }
    static var skipSizingReferenceCompleted: Bool { BuildConfig.skipSizingReferenceCompleted }
    static var shippingEnabled: Bool { BuildConfig.shippingEnabled }
    static var userAccessStatusPath: String { BuildConfig.userAccessStatusPath }

    static func authServicePath(_ relative: String) -> String {
        let base = authServiceBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let rel = relative.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard authApiUseLanguagePrefix else { return "\(base)/\(rel)" }
        return "\(base)/\(AppLocale.coreApiPathSegment)/\(rel)"
    }

    static func apiPath(_ relative: String) -> String {
        let base = apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let rel = relative.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard coreApiUseLanguagePrefix else { return "\(base)/\(rel)" }
        return "\(base)/\(AppLocale.coreApiPathSegment)/\(rel)"
    }

    static func apiPathWithoutLocale(_ relative: String) -> String {
        let base = apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let rel = relative.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(base)/\(rel)"
    }

    static func coreApiCandidateURLs(_ relative: String) -> [String] {
        let withLocale = apiPath(relative)
        guard coreApiUseLanguagePrefix else { return [withLocale] }
        let without = apiPathWithoutLocale(relative)
        return without == withLocale ? [withLocale] : [withLocale, without]
    }

    static func commonServicePath(_ relative: String) -> String {
        let rel = relative.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(commonServiceBaseURL)/\(rel)"
    }

    static func listingShareURL(listingId: String) -> String {
        let id = listingId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return "" }
        return "\(listingShareBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/\(id)"
    }

    static func legalTermsURL(languageTag: String) -> String {
        let lang = languageTag.lowercased().hasPrefix("en") ? "en" : "vi"
        return "\(legalPortalBaseURL)/\(lang)/terms"
    }

    static func legalPrivacyURL(languageTag: String) -> String {
        let lang = languageTag.lowercased().hasPrefix("en") ? "en" : "vi"
        return "\(legalPortalBaseURL)/\(lang)/privacy"
    }
}
