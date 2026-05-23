import Foundation

/// Compile-time business-flow gates — Android [BusinessFlowConfig].
enum BusinessFlowConfig {
    static var maxOffersPerConversation: Int { BuildConfig.chatMaxOffersPerConversation }
    static var c2cShipFulfillmentEnabled: Bool { BuildConfig.c2cShipFulfillmentEnabled }
    static var c2cShipOnlinePaymentEnabled: Bool { BuildConfig.c2cShipOnlinePaymentEnabled }
    static var c2cShipAndPaymentEnabled: Bool { c2cShipFulfillmentEnabled && c2cShipOnlinePaymentEnabled }
    static var c2cBuyNowEnabled: Bool { c2cShipAndPaymentEnabled }
    static var postRequireListingImages: Bool { BuildConfig.postRequireListingImages }
}
