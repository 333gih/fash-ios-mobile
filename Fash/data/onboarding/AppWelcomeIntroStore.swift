import Foundation

/// First-install welcome slide deck — shown once before login/guest. Android [AppWelcomeIntroStore].
enum AppWelcomeIntroStore {
    private static let keyPrefix = "app_welcome_intro_completed_v"

    /// Bump to replay intro for all users (e.g. major rebrand). Keep in sync with Android.
    static let currentVersion = 1

    private static func key(version: Int) -> String { keyPrefix + "\(version)" }

    static var hasCompleted: Bool {
        for version in 1...currentVersion {
            if UserDefaults.standard.bool(forKey: key(version: version)) {
                return true
            }
        }
        return false
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: key(version: currentVersion))
    }
}
