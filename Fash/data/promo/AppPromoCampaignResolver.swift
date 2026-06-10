import Foundation

/// Picks the highest-priority promo that passes gating and has not been dismissed.
enum AppPromoCampaignResolver {
    private static let welcomeId = "welcome"
    private static let welcomeVersion = 2
    private static let kycId = "kyc_verify"
    private static let kycVersion = 1
    private static let sellerPackageId = "seller_package"
    private static let sellerPackageVersion = 1
    private static let appRatingId = "app_rating"
    private static let appRatingVersion = 1
    private static let appRatingMinOpens = 3

    static func resolve(context: AppPromoGateContext) -> AppPromoCampaign? {
        guard baseEligible(context) else { return nil }

        if let remote = AppPromoPendingQueue.pollHighest(),
           AppPromoCampaignStore.canShow(remote) {
            return remote
        }

        if context.meetingKycReverifyRequired,
           !AppEnvironment.identityReverifyURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !AppPromoCampaignStore.isDismissed(campaignId: kycId, version: kycVersion) {
            return AppPromoCampaign(
                campaignId: kycId,
                version: kycVersion,
                kind: .kycVerification,
                remoteTitle: L10n.appPromoKycTitle,
                remoteMessage: L10n.appPromoKycMessage,
                remotePrimaryLabel: L10n.appPromoKycPrimary,
                remoteSecondaryLabel: L10n.appPromoSecondaryLater,
                remoteBadge: L10n.appPromoKycBadge
            )
        }

        if context.sellerPackagePromoEnabled,
           !AppPromoCampaignStore.isDismissed(campaignId: sellerPackageId, version: sellerPackageVersion) {
            return AppPromoCampaign(
                campaignId: sellerPackageId,
                version: sellerPackageVersion,
                kind: .sellerPackage,
                remoteTitle: L10n.appPromoSellerPackageTitle,
                remoteMessage: L10n.appPromoSellerPackageMessage,
                remotePrimaryLabel: L10n.appPromoSellerPackagePrimary,
                remoteSecondaryLabel: L10n.appPromoSecondaryLater,
                remoteBadge: L10n.appPromoSellerPackageBadge
            )
        }

        if context.appOpenCount >= appRatingMinOpens,
           !AppPromoCampaignStore.isDismissed(campaignId: appRatingId, version: appRatingVersion) {
            return AppPromoCampaign(
                campaignId: appRatingId,
                version: appRatingVersion,
                kind: .appRating,
                remoteTitle: L10n.appPromoRatingTitle,
                remoteMessage: L10n.appPromoRatingMessage,
                remotePrimaryLabel: L10n.appPromoRatingPrimary,
                remoteSecondaryLabel: L10n.appPromoSecondaryLater
            )
        }

        if !AppPromoCampaignStore.isDismissed(campaignId: welcomeId, version: welcomeVersion) {
            return AppPromoCampaign(
                campaignId: welcomeId,
                version: welcomeVersion,
                kind: .welcome,
                remoteTitle: L10n.welcomeBannerDialogTitle,
                remoteMessage: L10n.welcomeBannerDialogMessage,
                remotePrimaryLabel: L10n.welcomeBannerDialogAction
            )
        }

        return nil
    }

    private static func baseEligible(_ context: AppPromoGateContext) -> Bool {
        context.isAuthenticated && !context.blockPromoBecauseOtherUi && !context.needsOnboarding
    }
}

extension AppPromoGateContext {
    static func mainShell(
        isGuestMode: Bool,
        needsOnboarding: Bool,
        selectedConversationId: String?,
        appOpenCount: Int
    ) -> AppPromoGateContext {
        AppPromoGateContext(
            isAuthenticated: !isGuestMode,
            needsOnboarding: needsOnboarding,
            blockPromoBecauseOtherUi: selectedConversationId != nil,
            sellerPackagePromoEnabled: AppEnvironment.isDev,
            appOpenCount: appOpenCount,
            meetingKycReverifyRequired: false
        )
    }
}
