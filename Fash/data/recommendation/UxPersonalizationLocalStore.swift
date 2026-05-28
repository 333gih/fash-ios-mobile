import Foundation

/// Local fallback for tab defaults — Android [UxPersonalizationLocalStore].
enum UxPersonalizationLocalStore {
    private static let prefsName = "ux_personalization_local"

    static func readHomeDefaultTab(userId: String?) -> String? {
        let uid = normalizedUserId(userId)
        guard !uid.isEmpty else { return nil }
        return UserDefaults.standard.string(forKey: homeDefaultKey(uid))
    }

    static func writeHomeDefaultTab(userId: String?, tabKey: String) {
        let uid = normalizedUserId(userId)
        let key = tabKey.trimmingCharacters(in: .whitespaces)
        guard !uid.isEmpty, !key.isEmpty else { return }
        UserDefaults.standard.set(key, forKey: homeDefaultKey(uid))
    }

    static func readProfileDefaultTab(userId: String?) -> String? {
        let uid = normalizedUserId(userId)
        guard !uid.isEmpty else { return nil }
        return UserDefaults.standard.string(forKey: profileDefaultKey(uid))
    }

    static func writeProfileDefaultTab(userId: String?, tabKey: String) {
        let uid = normalizedUserId(userId)
        let key = tabKey.trimmingCharacters(in: .whitespaces)
        guard !uid.isEmpty, !key.isEmpty else { return }
        UserDefaults.standard.set(key, forKey: profileDefaultKey(uid))
    }

    static func clearForUser(userId: String?) {
        let uid = normalizedUserId(userId)
        guard !uid.isEmpty else { return }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: homeDefaultKey(uid))
        defaults.removeObject(forKey: profileDefaultKey(uid))
    }

    static func currentClientHour() -> Int {
        Calendar.current.component(.hour, from: Date())
    }

    private static func normalizedUserId(_ userId: String?) -> String {
        userId?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    }

    private static func homeDefaultKey(_ userId: String) -> String { "home_default_tab_\(userId)" }
    private static func profileDefaultKey(_ userId: String) -> String { "profile_default_tab_\(userId)" }
}
