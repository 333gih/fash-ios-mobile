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
