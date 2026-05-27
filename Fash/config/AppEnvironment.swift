import Foundation

/// Typed access to build config (Android [AppEnvironment]).
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
    static var authApplicationId: String { BuildConfig.authApplicationId }
    static var internalSecret: String { BuildConfig.internalSecret }
    static var internalServiceBearer: String { BuildConfig.internalServiceBearer }
    static var coreApiUseLanguagePrefix: Bool { BuildConfig.coreApiUseLanguagePrefix }
    static var authApiUseLanguagePrefix: Bool { BuildConfig.authApiUseLanguagePrefix }
    static var googleWebClientId: String { BuildConfig.googleWebClientId }
    static var googleIosClientId: String { BuildConfig.googleIosClientId }
    static var googleUrlScheme: String { BuildConfig.googleUrlScheme }
    static var facebookLoginEnabled: Bool { BuildConfig.facebookLoginEnabled }
    static var listingShareBaseURL: String { BuildConfig.listingShareBaseURL }
    static var legalPortalBaseURL: String { BuildConfig.legalPortalBaseURL }
    static var paymentRedirectURL: String { BuildConfig.paymentRedirectURL }
    static var identityReverifyURL: String { BuildConfig.identityReverifyURL }
    static var publicBrowseClientId: String { BuildConfig.publicBrowseClientId }
    static var publicBrowseClientToken: String { BuildConfig.publicBrowseClientToken }
    static var skipSizingReferenceCompleted: Bool { BuildConfig.skipSizingReferenceCompleted }
    static var shippingEnabled: Bool { BuildConfig.shippingEnabled }
    static var userAccessStatusPath: String { BuildConfig.userAccessStatusPath }

    static var authOtpRequestPath: String { BuildConfig.authOtpRequestPath }
    static var authOtpVerifyPath: String { BuildConfig.authOtpVerifyPath }
    static var authLoginPath: String { BuildConfig.authLoginPath }
    static var authRefreshPath: String { BuildConfig.authRefreshPath }
    static var authLogoutPath: String { BuildConfig.authLogoutPath }
    static var authLogoutAllPath: String { BuildConfig.authLogoutAllPath }
    static var authFcmRegisterPath: String { BuildConfig.authFcmRegisterPath }
    static var authChangePasswordPath: String { BuildConfig.authChangePasswordPath }
    static var authMePath: String { BuildConfig.authMePath }
    static var authSocialLoginPath: String { BuildConfig.authSocialLoginPath }
    static var corePaymentInitiatePath: String { BuildConfig.corePaymentInitiatePath }

    static func authServicePath(_ relative: String) -> String {
        let base = authServiceBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let rel = relative.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard authApiUseLanguagePrefix else { return "\(base)/\(rel)" }
        return "\(base)/\(AppLocale.coreApiPathSegment())/\(rel)"
    }

    static func apiPath(_ relative: String) -> String {
        let base = apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let rel = relative.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard coreApiUseLanguagePrefix else { return "\(base)/\(rel)" }
        return "\(base)/\(AppLocale.coreApiPathSegment())/\(rel)"
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

    static func commonServiceHealthURL() -> String { "\(commonServiceBaseURL)/health" }

    static func listingShareURL(listingId: String) -> String {
        let id = listingId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return "" }
        return "\(listingShareBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/\(id)"
    }

    static func profileShareURL(username: String) -> String {
        let handle = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !handle.isEmpty else { return "" }
        let base = listingShareBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let profileBase: String
        if base.lowercased().hasSuffix("/p/l") {
            profileBase = String(base.dropLast(1)) + "u"
        } else {
            profileBase = "\(base)/u"
        }
        return "\(profileBase)/\(handle)"
    }

    static func legalTermsURL(languageTag: String) -> String {
        let lang = languageTag.lowercased().hasPrefix("en") ? "en" : "vi"
        return "\(legalPortalBaseURL)/\(lang)/terms"
    }

    static func legalPrivacyURL(languageTag: String) -> String {
        let lang = languageTag.lowercased().hasPrefix("en") ? "en" : "vi"
        return "\(legalPortalBaseURL)/\(lang)/privacy"
    }

    static func corePaymentInitiateURL(orderId: String) -> String {
        let path = String(format: corePaymentInitiatePath, orderId)
        return apiPath(path)
    }
}
