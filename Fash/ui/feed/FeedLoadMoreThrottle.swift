import Foundation

/// Shared scroll-pagination pacing — avoids hammering core-service when the feed footer retriggers.
enum FeedLoadMoreThrottle {
    static let defaultInterval: TimeInterval = 0.4
    static let followingInterval: TimeInterval = 0.9
    private static let rateLimitFloor: TimeInterval = 2.0

    static func canLoad(lastAt: Date?, minInterval: TimeInterval = defaultInterval) -> Bool {
        guard let lastAt else { return true }
        return Date().timeIntervalSince(lastAt) >= minInterval
    }

    static func isBlocked(until: Date?) -> Bool {
        guard let until else { return false }
        return Date() < until
    }

    static func blockedUntil(afterRateLimit retryAfterSeconds: Int?) -> Date {
        let wait: TimeInterval
        if let retryAfterSeconds, retryAfterSeconds > 0 {
            wait = max(rateLimitFloor, TimeInterval(retryAfterSeconds))
        } else {
            wait = rateLimitFloor
        }
        return Date().addingTimeInterval(wait)
    }

    static func blockedUntil(after error: Error) -> Date? {
        guard let http = error as? CoreServiceHttpException, http.isRateLimited else { return nil }
        return blockedUntil(afterRateLimit: http.retryAfterSeconds)
    }
}
