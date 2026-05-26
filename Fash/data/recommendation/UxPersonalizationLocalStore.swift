import Foundation

/// Port of Android `UxPersonalizationLocalStore` (data.recommendation).
enum UxPersonalizationLocalStore {
    private static let prefsName = "ux_personalization_local"

    static func clearForUser(userId: String?) {
        let uid = userId?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !uid.isEmpty else { return }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: homeDefaultKey(uid))
        defaults.removeObject(forKey: profileDefaultKey(uid))
    }

    private static func homeDefaultKey(_ userId: String) -> String { "home_default_tab_\(userId)" }
    private static func profileDefaultKey(_ userId: String) -> String { "profile_default_tab_\(userId)" }
}
