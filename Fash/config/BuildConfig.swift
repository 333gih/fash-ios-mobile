import Foundation

/// Active build flavor — mirrors Android [BuildConfig] from env/{dev,prod}.env.
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
    static var authClientSecret: String { C.authClientSecret }
    static var googleWebClientId: String { C.googleWebClientId }
    static var facebookAppId: String { C.facebookAppId }
    static var facebookClientToken: String { C.facebookClientToken }
    static var facebookLoginEnabled: Bool { C.facebookLoginEnabled }
    static var listingShareBaseURL: String { C.listingShareBaseURL }
    static var legalPortalBaseURL: String { C.legalPortalBaseURL }
    static var paymentRedirectURL: String { C.paymentRedirectURL }
    static var identityReverifyURL: String { C.identityReverifyURL }
    static var publicBrowseClientId: String { C.publicBrowseClientId }
    static var publicBrowseClientToken: String { C.publicBrowseClientToken }
    static var internalSecret: String { C.internalSecret }
    static var internalServiceBearer: String { C.internalServiceBearer }
    static var userAccessStatusPath: String { C.userAccessStatusPath }
    static var corePaymentInitiatePath: String { C.corePaymentInitiatePath }
    static var coreApiUseLanguagePrefix: Bool { C.coreApiUseLanguagePrefix }
    static var authApiUseLanguagePrefix: Bool { C.authApiUseLanguagePrefix }
    static var shippingEnabled: Bool { C.shippingEnabled }
    static var skipSizingReferenceCompleted: Bool { C.skipSizingReferenceCompleted }
    static var c2cShipFulfillmentEnabled: Bool { C.c2cShipFulfillmentEnabled }
    static var c2cShipOnlinePaymentEnabled: Bool { C.c2cShipOnlinePaymentEnabled }
    static var postRequireListingImages: Bool { C.postRequireListingImages }
    static var chatMaxOffersPerConversation: Int { C.chatMaxOffersPerConversation }

    static var authOtpRequestPath: String { C.authOtpRequestPath }
    static var authOtpVerifyPath: String { C.authOtpVerifyPath }
    static var authLoginPath: String { C.authLoginPath }
    static var authRefreshPath: String { C.authRefreshPath }
    static var authLogoutPath: String { C.authLogoutPath }
    static var authLogoutAllPath: String { C.authLogoutAllPath }
    static var authFcmRegisterPath: String { C.authFcmRegisterPath }
    static var authChangePasswordPath: String { C.authChangePasswordPath }
    static var authMePath: String { C.authMePath }
    static var authSocialLoginPath: String { C.authSocialLoginPath }
}
