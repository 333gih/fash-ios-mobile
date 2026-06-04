import Foundation

/// Shared stall window before showing “try again later” on feed/profile grids.
enum FeedLoadStallPolicy {
    static let timeoutSeconds: TimeInterval = 2.0
}
