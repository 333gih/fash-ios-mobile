import Foundation

/// Pre-login mascot guide (after welcome intro, before post-login shell tour). Independent skip state.
enum PreLoginMascotGuideStore {
    private static let keyPrefix = "pre_login_mascot_guide_completed_v"
    static let currentVersion = 1

    private static func key(version: Int) -> String { keyPrefix + "\(version)" }

    static var hasCompleted: Bool {
        for version in 1...currentVersion {
            if UserDefaults.standard.bool(forKey: key(version: version)) { return true }
        }
        return false
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: key(version: currentVersion))
    }
}
