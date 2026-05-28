import Foundation

/// Stable anonymous session id for guest feed events — Android [BrowseSessionStore].
final class BrowseSessionStore {
    private static let prefsName = "fash_browse_session"
    private static let guestKey = "guest_session_id"

    func guestSessionId() -> String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: Self.guestKey), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        defaults.set(id, forKey: Self.guestKey)
        return id
    }

    func sessionIdForUser(_ userId: String) -> String {
        "u:\(userId.trimmingCharacters(in: .whitespacesAndNewlines))"
    }
}
