import Foundation

/// Lenient checks for meetup map links — Android `ChatMapsUrlRules`.
enum ChatMapsUrlRules {
    private static let hints = [
        "maps.app.goo.gl",
        "goo.gl/maps",
        "google.com/maps",
        "maps.google.com",
        "share.google/",
    ]

    static func isLenientMeetingMapsUrl(_ url: String) -> Bool {
        let u = url.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !u.isEmpty else { return false }
        return hints.contains { u.contains($0) }
    }
}
