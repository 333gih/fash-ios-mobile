import Foundation

/// Tracks whether the user dismissed the Home "Add your size" banner — Android [HomeSizingBannerPreference].
enum HomeSizingBannerPreference {
    private static let prefsName = "fash_app_prefs"
    private static let dismissedKey = "home_sizing_banner_dismissed"

    static func isDismissed() -> Bool {
        UserDefaults.standard.bool(forKey: dismissedKey)
    }

    static func markDismissed() {
        UserDefaults.standard.set(true, forKey: dismissedKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: dismissedKey)
    }
}
