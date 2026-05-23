import Foundation

final class BrowseSessionStore {
    private let key = "fash_browse_session_id"
    var sessionId: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
