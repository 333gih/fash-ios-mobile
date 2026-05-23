import Foundation

/// Active build flavor config (Android BuildConfig). Xcode scheme selects Dev vs Prod file via SWIFT_ACTIVE_COMPILATION_CONDITIONS.
enum BuildConfig {
    #if DEV
    private typealias C = GeneratedBuildConfig_Dev
    #elseif PROD
    private typealias C = GeneratedBuildConfig_Prod
    #else
    private typealias C = GeneratedBuildConfig_Dev
    #endif

    static var environmentName: String { C.environmentName }
    static var flavor: String { C.flavor }
    static var bundleId: String { C.bundleId }
    static var authServiceBaseURL: String { C.authServiceBaseURL }
    static var apiBaseURL: String { C.apiBaseURL }
    static var commonServiceBaseURL: String { C.commonServiceBaseURL }
    static var realtimeBaseURL: String { C.realtimeBaseURL }
    static var authClientId: String { C.authClientId }
    static var authApplicationId: String { C.authApplicationId }
    static var googleWebClientId: String { C.googleWebClientId }
    static var listingShareBaseURL: String { C.listingShareBaseURL }
    static var legalPortalBaseURL: String { C.legalPortalBaseURL }
    static var publicBrowseClientId: String { C.publicBrowseClientId }
    static var publicBrowseClientToken: String { C.publicBrowseClientToken }
    static var internalSecret: String { C.internalSecret }
    static var internalServiceBearer: String { C.internalServiceBearer }
    static var userAccessStatusPath: String { C.userAccessStatusPath }
    static var coreApiUseLanguagePrefix: Bool { C.CORE_API_USE_LANGUAGE_PREFIX }
    static var authApiUseLanguagePrefix: Bool { C.AUTH_API_USE_LANGUAGE_PREFIX }
    static var shippingEnabled: Bool { C.SHIPPING }
    static var skipSizingReferenceCompleted: Bool { C.SKIP_SIZING_REFERENCE_COMPLETED }
}
