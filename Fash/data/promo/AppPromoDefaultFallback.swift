import Foundation

/// Guaranteed app-open promo when remote catalog and carousel slides are unavailable.
enum AppPromoDefaultFallback {
    private struct DefaultPromo {
        let idSuffix: String
        let title: String
        let message: String
        let badge: String?
    }

    private static let version = 1
    private static let cooldownHours = 4
    private static let maxShowsPerDay = 3

    private static let promos: [DefaultPromo] = [
        DefaultPromo(idSuffix: "m01", title: L10n.appPromoDefaultM01Title, message: L10n.appPromoDefaultM01Body, badge: nil),
        DefaultPromo(idSuffix: "m02", title: L10n.appPromoDefaultM02Title, message: L10n.appPromoDefaultM02Body, badge: nil),
        DefaultPromo(idSuffix: "m03", title: L10n.appPromoDefaultM03Title, message: L10n.appPromoDefaultM03Body, badge: nil),
        DefaultPromo(idSuffix: "m04", title: L10n.appPromoDefaultM04Title, message: L10n.appPromoDefaultM04Body, badge: nil),
        DefaultPromo(idSuffix: "m05", title: L10n.appPromoDefaultM05Title, message: L10n.appPromoDefaultM05Body, badge: nil),
        DefaultPromo(idSuffix: "m06", title: L10n.appPromoDefaultM06Title, message: L10n.appPromoDefaultM06Body, badge: nil),
        DefaultPromo(idSuffix: "m07", title: L10n.appPromoDefaultM07Title, message: L10n.appPromoDefaultM07Body, badge: nil),
        DefaultPromo(idSuffix: "m08", title: L10n.appPromoDefaultM08Title, message: L10n.appPromoDefaultM08Body, badge: nil),
        DefaultPromo(idSuffix: "m09", title: L10n.appPromoDefaultM09Title, message: L10n.appPromoDefaultM09Body, badge: nil),
        DefaultPromo(idSuffix: "m10", title: L10n.appPromoDefaultM10Title, message: L10n.appPromoDefaultM10Body, badge: nil),
        DefaultPromo(idSuffix: "m11", title: L10n.appPromoDefaultM11Title, message: L10n.appPromoDefaultM11Body, badge: nil),
        DefaultPromo(idSuffix: "m12", title: L10n.appPromoDefaultM12Title, message: L10n.appPromoDefaultM12Body, badge: L10n.appPromoDefaultEsgBadge),
    ]

    static func resolve() -> AppPromoCampaign? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
        let month = cal.component(.month, from: Date())
        let day = cal.component(.day, from: Date())
        let pick = promos[(month - 1) % promos.count]
        let campaign = AppPromoCampaign(
            campaignId: "default_app_open_\(pick.idSuffix)_\(month)_\(day)",
            version: version,
            kind: .remote,
            remoteTitle: pick.title,
            remoteMessage: pick.message,
            remoteBadge: pick.badge,
            remotePrimaryLabel: L10n.appPromoDefaultPrimary,
            remoteSecondaryLabel: L10n.appPromoSecondaryLater,
            primaryAction: AppPromoButtonAction(type: "in_app_explore", payload: ""),
            priority: 40,
            scheduleType: "on_app_open",
            maxShowsPerUser: maxShowsPerDay,
            cooldownHours: cooldownHours
        )
        return AppPromoCampaignStore.canShow(campaign) ? campaign : nil
    }
}
