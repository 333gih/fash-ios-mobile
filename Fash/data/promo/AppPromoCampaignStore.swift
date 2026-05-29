import Foundation

/// Persists dismissals and app-open counters — Android `AppPromoCampaignStore`.
enum AppPromoCampaignStore {
    private static let prefsName = "fash_app_prefs"
    private static let dismissedPrefix = "app_promo_dismissed_"
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

    static func incrementAppOpenCount() -> Int {
        let next = defaults.integer(forKey: appOpenCountKey) + 1
        defaults.set(next, forKey: appOpenCountKey)
        return next
    }

    private static func dismissedKey(campaignId: String, version: Int) -> String {
        "\(dismissedPrefix)\(campaignId)_v\(version)"
    }
}
