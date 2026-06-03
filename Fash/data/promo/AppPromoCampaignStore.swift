import Foundation

/// Persists dismissals, show counts, and app-open counters — Android `AppPromoCampaignStore`.
enum AppPromoCampaignStore {
    private static let prefsName = "fash_app_prefs"
    private static let dismissedPrefix = "app_promo_dismissed_"
    private static let showCountPrefix = "app_promo_shows_"
    private static let lastShownPrefix = "app_promo_last_shown_"
    private static let appOpenCountKey = "app_promo_app_open_count"
    private static let legacyWelcomePrefix = "welcome_center_banner_dismissed_v"

    private static var defaults: UserDefaults { UserDefaults.standard }

    static func isDismissed(_ campaign: AppPromoCampaign) -> Bool {
        isDismissed(campaignId: campaign.campaignId, version: campaign.version)
    }

    static func isDismissed(campaignId: String, version: Int) -> Bool {
        if campaignId == "welcome", defaults.bool(forKey: legacyWelcomePrefix + String(version)) {
            return true
        }
        return defaults.bool(forKey: dismissedKey(campaignId: campaignId, version: version))
    }

    static func markDismissed(_ campaign: AppPromoCampaign) {
        markDismissed(campaignId: campaign.campaignId, version: campaign.version)
    }

    static func markDismissed(campaignId: String, version: Int) {
        defaults.set(true, forKey: dismissedKey(campaignId: campaignId, version: version))
    }

    /// Whether this campaign may be shown (dismissal, max shows, cooldown from admin CMS).
    static func canShow(_ campaign: AppPromoCampaign) -> Bool {
        guard !isDismissed(campaign) else { return false }
        let shows = readShowCount(campaignId: campaign.campaignId, version: campaign.version)
        if let max = campaign.maxShowsPerUser, max > 0, shows >= max {
            return false
        }
        if let hours = campaign.cooldownHours, hours > 0,
           let last = readLastShownAt(campaignId: campaign.campaignId, version: campaign.version) {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed < TimeInterval(hours) * 3600 {
                return false
            }
        }
        return true
    }

    static func hasRecordedShow(_ campaign: AppPromoCampaign) -> Bool {
        readShowCount(campaignId: campaign.campaignId, version: campaign.version) > 0
    }

    static func recordShow(_ campaign: AppPromoCampaign) {
        let key = showCountKey(campaignId: campaign.campaignId, version: campaign.version)
        let next = defaults.integer(forKey: key) + 1
        defaults.set(next, forKey: key)
        defaults.set(Date().timeIntervalSince1970, forKey: lastShownKey(campaignId: campaign.campaignId, version: campaign.version))
    }

    static func incrementAppOpenCount() -> Int {
        let next = defaults.integer(forKey: appOpenCountKey) + 1
        defaults.set(next, forKey: appOpenCountKey)
        return next
    }

    private static func readShowCount(campaignId: String, version: Int) -> Int {
        defaults.integer(forKey: showCountKey(campaignId: campaignId, version: version))
    }

    private static func readLastShownAt(campaignId: String, version: Int) -> Date? {
        let raw = defaults.double(forKey: lastShownKey(campaignId: campaignId, version: version))
        guard raw > 0 else { return nil }
        return Date(timeIntervalSince1970: raw)
    }

    private static func dismissedKey(campaignId: String, version: Int) -> String {
        "\(dismissedPrefix)\(campaignId)_v\(version)"
    }

    private static func showCountKey(campaignId: String, version: Int) -> String {
        "\(showCountPrefix)\(campaignId)_v\(version)"
    }

    private static func lastShownKey(campaignId: String, version: Int) -> String {
        "\(lastShownPrefix)\(campaignId)_v\(version)"
    }
}
