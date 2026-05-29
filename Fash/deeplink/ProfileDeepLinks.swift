import Foundation

/// Port of Android `ProfileDeepLinks` (deeplink).
enum ProfileDeepLinks {
    static func normalizeUsername(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }

    /// `fash://profile/{username}` — opens seller shop when app is installed.
    static func fashProfileURL(username: String) -> URL? {
        let handle = normalizeUsername(username)
        guard !handle.isEmpty else { return nil }
        return URL(string: "fash://profile/\(handle)")
    }
}
