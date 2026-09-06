import Foundation

/// Shared stall window before showing “try again later” on feed/profile grids.
enum FeedLoadStallPolicy {
    /// Must exceed typical cold-start explore-listings latency (~3–6s) so the grid
    /// does not flash the hard-error CTA while the request is still in flight.
    /// Aligns with Android `TAB_LOAD_TIMEOUT_MS` window for first-page patience.
    static let timeoutSeconds: TimeInterval = 12.0
}
