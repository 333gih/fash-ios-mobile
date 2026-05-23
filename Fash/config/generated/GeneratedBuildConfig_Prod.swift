// Generated from env/prod.env — mirrors Android BuildConfig injectFromEnv
import Foundation

enum GeneratedBuildConfig_Prod {
    static let environmentName: String = "prod"
    static let flavor: String = "prod"
    static let bundleId: String = "com.pc.fash-ios-mobile"
    static let authServiceBaseURL: String = "https://api-auth.fashandcurious.com/"
    static let apiBaseURL: String = "https://api-core.fashandcurious.com/"
    static let commonServiceBaseURL: String = "https://api-common.fashandcurious.com/"
    static let realtimeBaseURL: String = "https://api-realtime.fashandcurious.com/"
    static let authClientId: String = "fash-android-dev"
    static let authApplicationId: String = "web"
    static let authClientSecret: String = ""
    static let googleWebClientId: String = "598587496348-3m7us7ap54ia5clqvag38ctqbuqefasf.apps.googleusercontent.com"
    static let facebookAppId: String = "940995382097327"
    static let facebookClientToken: String = "23dff93cd150b947ceb55afdcec6f4d6"
    static let listingShareBaseURL: String = "https://fashandcurious.com/p/l"
    static let legalPortalBaseURL: String = "https://fashandcurious.com"
    static let paymentRedirectURL: String = "https://api-payment.fashandcurious.com/payment/callback"
    static let identityReverifyURL: String = ""
    static let publicBrowseClientId: String = "fash-android"
    static let publicBrowseClientToken: String = "4bNy8z9TaA1qVb4rmUDqPFyKs6Gp7x3JXwZmFyAPQkY2RCesuKcTmN5Btb"
    static let internalSecret: String = "8b4d4f3b6c3d45c5e21c2e1a8f1f5b8a4c1d9e7a2f8c6d4b"
    static let internalServiceBearer: String = "8b4d4f3b6c3d45c5e21c2e1a8f1f5b8a4c1d9e7a2f8c6d4b"
    static let userAccessStatusPath: String = "api/v1/users/me/setup-status"
    static let corePaymentInitiatePath: String = "api/v1/orders/%s/payments/initiate"
    static let authOtpRequestPath: String = "api/v1/auth/otp/request"
    static let authOtpVerifyPath: String = "api/v1/auth/otp/verify"
    static let authLoginPath: String = "api/v1/auth/login"
    static let authRefreshPath: String = "api/v1/auth/refresh"
    static let authLogoutPath: String = "api/v1/auth/logout"
    static let authLogoutAllPath: String = "api/v1/auth/logout-all"
    static let authFcmRegisterPath: String = "api/v1/auth/fcm/register"
    static let authChangePasswordPath: String = "api/v1/auth/change-password"
    static let authMePath: String = "api/v1/auth/me"
    static let authSocialLoginPath: String = "api/v1/auth/social-login"
    static let coreApiUseLanguagePrefix: Bool = true
    static let authApiUseLanguagePrefix: Bool = true
    static let shippingEnabled: Bool = true
    static let skipSizingReferenceCompleted: Bool = false
    static let c2cShipFulfillmentEnabled: Bool = false
    static let c2cShipOnlinePaymentEnabled: Bool = false
    static let postRequireListingImages: Bool = true
    static let facebookLoginEnabled: Bool = false
    static let chatMaxOffersPerConversation: Int = 3
}
