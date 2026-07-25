import SwiftUI

enum NotificationGroups {
    static let system = "SYSTEM"
    static let commerce = "COMMERCE"
    static let social = "SOCIAL"
    static let recommendation = "RECOMMENDATION"
    static let ads = "ADS"
    static let reengagement = "REENGAGEMENT"
    static let realtime = "REALTIME"

    static let displayOrder = [system, commerce, social, recommendation, ads, reengagement, realtime]

    /// Compact row height so all 7 groups fit on one screen.
    static let rowHeight: CGFloat = 56
}

func notificationGroupTitle(_ group: String) -> String {
    switch group {
    case NotificationGroups.system: return L10n.notificationGroupSystem
    case NotificationGroups.commerce: return L10n.notificationGroupCommerce
    case NotificationGroups.social: return L10n.notificationGroupSocial
    case NotificationGroups.recommendation: return L10n.notificationGroupRecommendation
    case NotificationGroups.ads: return L10n.notificationGroupAds
    case NotificationGroups.reengagement: return L10n.notificationGroupReengagement
    case NotificationGroups.realtime: return L10n.notificationGroupRealtime
    default: return L10n.notificationGroupSystem
    }
}

func notificationGroupSubtitle(_ group: String) -> String {
    switch group {
    case NotificationGroups.system: return L10n.notificationGroupSystemDesc
    case NotificationGroups.commerce: return L10n.notificationGroupCommerceDesc
    case NotificationGroups.social: return L10n.notificationGroupSocialDesc
    case NotificationGroups.recommendation: return L10n.notificationGroupRecommendationDesc
    case NotificationGroups.ads: return L10n.notificationGroupAdsDesc
    case NotificationGroups.reengagement: return L10n.notificationGroupReengagementDesc
    case NotificationGroups.realtime: return L10n.notificationGroupRealtimeDesc
    default: return L10n.notificationGroupSystemDesc
    }
}

func notificationGroupHasActivity(_ group: NotificationGroupSummaryItem) -> Bool {
    group.unreadCount > 0 || !(group.latestId?.isEmpty ?? true)
}

func notificationGroupSystemImage(_ group: String) -> String {
    switch group {
    case NotificationGroups.system: return "gearshape"
    case NotificationGroups.commerce: return "bag"
    case NotificationGroups.social: return "person.2"
    case NotificationGroups.recommendation: return "sparkles"
    case NotificationGroups.ads: return "megaphone"
    case NotificationGroups.reengagement: return "arrow.counterclockwise"
    case NotificationGroups.realtime: return "bubble.left.and.bubble.right"
    default: return "bell"
    }
}

func notificationPayloadSystemImage(_ payloadType: String?) -> String {
    let pt = payloadType?.lowercased() ?? ""
    if pt.contains("follower") { return "person.2" }
    if pt.contains("liked") { return "heart" }
    if pt.contains("chat.message") { return "bubble.left" }
    if pt.contains("order") || pt.contains("offer") { return "bag" }
    if pt.contains("promo") || pt.contains("app_promo") { return "megaphone" }
    if pt.contains("referral") { return "gift" }
    return "bell"
}

func notificationRowImageURL(_ item: InboxNotificationItem) -> URL? {
    guard let data = item.dataMap else { return nil }
    let keys = ["notification_image_url", "notificationImageUrl", "image_url", "imageUrl"]
    for key in keys {
        if let raw = data[key] as? String, let url = URL(string: raw), !raw.isEmpty {
            return url
        }
    }
    return nil
}

/** Maps server `notification_group` / payload_type to inbox group — mirrors core-service ResolveGroup. */
func resolveInboxNotificationGroup(_ item: InboxNotificationItem) -> String {
    if let group = item.notificationGroup?.trimmingCharacters(in: .whitespacesAndNewlines), !group.isEmpty {
        return group.uppercased()
    }
    let pt = item.payloadType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    if pt.hasPrefix("recommendation.") || pt.hasPrefix("marketplace.recommendation.") {
        switch pt {
        case "marketplace.recommendation.inactive_nudge",
             "marketplace.recommendation.inactive_ladder",
             "marketplace.recommendation.sustainable_impact",
             "marketplace.recommendation.daily_comeback",
             "marketplace.recommendation.ai_re_engagement":
            return NotificationGroups.reengagement
        default:
            return NotificationGroups.recommendation
        }
    }
    switch pt {
    case "marketplace.follower.new", "marketplace.follower.batch",
         "marketplace.listing.liked", "marketplace.listing.liked.batch",
         "marketplace.listing.approved_for_followers":
        return NotificationGroups.social
    case "marketplace.chat.message":
        return NotificationGroups.realtime
    case "marketplace.chat.offer_received", "marketplace.chat.offer_accepted", "marketplace.chat.offer_declined",
         "marketplace.order.created", "marketplace.order.shipped", "marketplace.order.cancelled",
         "marketplace.order.meetup_aborted", "marketplace.order.funds_released", "marketplace.order.dispute_opened",
         "marketplace.review.received":
        return NotificationGroups.commerce
    case "marketplace.referral.invite_rewarded":
        return NotificationGroups.reengagement
    case "admin.mobile_push.promo", "admin.app_promo_interstitial":
        return NotificationGroups.ads
    default:
        return NotificationGroups.system
    }
}
