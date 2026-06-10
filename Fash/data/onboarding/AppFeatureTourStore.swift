import Foundation

/// One-time guided tour over the main shell — Android [AppFeatureTourStore].
enum AppFeatureTourStore {
    private static let prefsName = "fash_app_prefs"
    private static let keyPrefix = "app_feature_tour_completed_v"

    /// Increment to replay the tour for all users. Keep in sync with Android.
    static let currentTourVersion = 2

    private static func key(version: Int) -> String { keyPrefix + "\(version)" }

    static func isCompletedForCurrentVersion() -> Bool {
        for version in 1...currentTourVersion {
            if UserDefaults.standard.bool(forKey: key(version: version)) {
                return true
            }
        }
        return false
    }

    static func markCompletedForCurrentVersion() {
        UserDefaults.standard.set(true, forKey: key(version: currentTourVersion))
    }

    /// Returning users who already finished onboarding should not see the shell tour again.
    static func markCompletedIfPreviouslyOnboarded(onboardingDone: Bool) {
        if onboardingDone {
            markCompletedForCurrentVersion()
        }
    }
}
