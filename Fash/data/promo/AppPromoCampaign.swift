import Foundation

enum AppPromoCampaignKind: Equatable {
    case welcome
    case appRating
    case sellerPackage
    case kycVerification
    case remote
}

struct AppPromoButtonAction: Equatable {
    let type: String
    let payload: String
}

struct AppPromoCampaign: Equatable, Identifiable {
    let campaignId: String
    let version: Int
    let kind: AppPromoCampaignKind
    var remoteTitle: String?
    var remoteMessage: String?
    var remoteImageUrls: [String] = []
    var remoteBadge: String?
    var remotePrimaryLabel: String?
    var remoteSecondaryLabel: String?
    var primaryAction: AppPromoButtonAction?
    var secondaryAction: AppPromoButtonAction?
    var priority: Int = 0
    var scheduleType: String?

    var id: String { campaignId }
    var isRemote: Bool { kind == .remote }
}

struct AppPromoGateContext: Equatable {
    var isAuthenticated: Bool
    var needsOnboarding: Bool
    var blockPromoBecauseOtherUi: Bool
    var sellerPackagePromoEnabled: Bool
    var appOpenCount: Int
}
