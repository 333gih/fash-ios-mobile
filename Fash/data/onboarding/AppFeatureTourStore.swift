import Foundation

/// One-time guided tour over the main shell — Android [AppFeatureTourStore].
enum AppFeatureTourStore {
    private static let prefsName = "fash_app_prefs"
    private static let keyPrefix = "app_feature_tour_completed_v"

    /// Increment to replay the tour for all users.
    static let currentTourVersion = 2

    private static var key: String { keyPrefix + "\(currentTourVersion)" }

    static func isCompletedForCurrentVersion() -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markCompletedForCurrentVersion() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
