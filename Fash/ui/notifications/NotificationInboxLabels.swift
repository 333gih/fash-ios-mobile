import Foundation

/// Maps inbox `payload_type` / `source` to user-facing copy — Android `NotificationInboxLabels.kt`.
enum NotificationInboxLabels {
    static func payloadTypeLabel(_ payloadType: String) -> String? {
        switch payloadType {
        case "marketplace.follower.new": return L10n.notificationPtMarketplaceFollowerNew
        case "marketplace.follower.batch": return L10n.notificationPtMarketplaceFollowerBatch
        case "marketplace.listing.liked": return L10n.notificationPtMarketplaceListingLiked
        case "marketplace.listing.liked.batch": return L10n.notificationPtMarketplaceListingLikedBatch
        case "marketplace.listing.approved_for_followers": return L10n.notificationPtMarketplaceListingApprovedForFollowers
        case "marketplace.listing.approved": return L10n.notificationPtMarketplaceListingApproved
        case "marketplace.chat.message": return L10n.notificationPtMarketplaceChatMessage
        case "marketplace.chat.offer_received": return L10n.notificationPtMarketplaceChatOfferReceived
        case "marketplace.chat.offer_accepted": return L10n.notificationPtMarketplaceChatOfferAccepted
        case "marketplace.chat.offer_declined": return L10n.notificationPtMarketplaceChatOfferDeclined
        case "marketplace.order.created": return L10n.notificationPtMarketplaceOrderCreated
        case "marketplace.order.shipped": return L10n.notificationPtMarketplaceOrderShipped
        case "marketplace.order.cancelled": return L10n.notificationPtMarketplaceOrderCancelled
        case "marketplace.order.meetup_aborted": return L10n.notificationPtMarketplaceOrderMeetupAborted
        case "marketplace.order.funds_released": return L10n.notificationPtMarketplaceOrderFundsReleased
        case "marketplace.order.dispute_opened": return L10n.notificationPtMarketplaceOrderDisputeOpened
        case "marketplace.review.received": return L10n.notificationPtMarketplaceReviewReceived
        case "marketplace.referral.invite_rewarded": return L10n.notificationPtMarketplaceReferralInviteRewarded
        case "marketplace.recommendation.daily_digest": return L10n.notificationPtMarketplaceRecommendationDailyDigest
        case "marketplace.recommendation.style_fresh": return L10n.notificationPtMarketplaceRecommendationStyleFresh
        case "marketplace.recommendation.similar_saved": return L10n.notificationPtMarketplaceRecommendationSimilarSaved
        case "marketplace.recommendation.continue_browsing": return L10n.notificationPtMarketplaceRecommendationContinueBrowsing
        case "marketplace.recommendation.inactive_nudge": return L10n.notificationPtMarketplaceRecommendationInactiveNudge
        case "marketplace.recommendation.inactive_ladder": return L10n.notificationPtMarketplaceRecommendationInactiveLadder
        case "marketplace.recommendation.sustainable_impact": return L10n.notificationPtMarketplaceRecommendationSustainableImpact
        case "marketplace.recommendation.community_quiet": return L10n.notificationPtMarketplaceRecommendationCommunityQuiet
        case "marketplace.recommendation.style_drought": return L10n.notificationPtMarketplaceRecommendationStyleDrought
        case "marketplace.recommendation.taste_neighbor": return L10n.notificationPtMarketplaceRecommendationTasteNeighbor
        case "marketplace.recommendation.hunt_today": return L10n.notificationPtMarketplaceRecommendationHuntToday
        case "marketplace.recommendation.social_style_match": return L10n.notificationPtMarketplaceRecommendationSocialStyleMatch
        case "admin.mobile_push": return L10n.notificationPtAdminMobilePush
        case "admin.mobile_push.announcement": return L10n.notificationPtAdminMobilePushAnnouncement
        case "admin.mobile_push.promo": return L10n.notificationPtAdminMobilePushPromo
        case "admin.mobile_push.transactional": return L10n.notificationPtAdminMobilePushTransactional
        case "admin.mobile_push.ops": return L10n.notificationPtAdminMobilePushOps
        case "admin.app_promo_interstitial": return L10n.notificationPtAdminAppPromoInterstitial
        default: return nil
        }
    }

    static func sourceLabel(_ source: String) -> String? {
        switch source {
        case "kafka": return L10n.notificationSrcKafka
        case "core_local": return L10n.notificationSrcCoreLocal
        default: return nil
        }
    }
}
