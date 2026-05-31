import Foundation

/// Feed event surfaces — must match core-service `FeedSurface*` constants.
enum FeedSurfaces {
    static let appOpen = "app_open"
    static let notificationOpen = "notification_open"

    /// Placeholder listing id for session-level events (no listing context).
    static let sessionSentinelListingId = "00000000-0000-4000-8090-000000000001"
}
