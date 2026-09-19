import SwiftUI

/// Named animation constants — iOS port of the cross-platform FASH motion language.
///
/// Centralises all animation durations and curves so changes propagate consistently.
/// Use named animations instead of inline `.easeInOut(duration: 0.22)` literals.
enum FashMotion {

    // MARK: - Durations

    static let quick: Double = 0.14
    static let short: Double = 0.18
    static let standard: Double = 0.22
    static let medium: Double = 0.25
    static let long: Double = 0.35

    // MARK: - Named Animations

    /// Tab bar selection indicator slide.
    static let tabBar = Animation.easeInOut(duration: medium)

    /// Tab content crossfade when switching feed tabs.
    static let tabContent = Animation.easeInOut(duration: short)

    /// General overlay fade/slide — sticky chrome, snackbars, sheets.
    static let overlay = Animation.easeInOut(duration: standard)

    /// Sticky chrome appear/disappear in Explore.
    static let stickyChrome = Animation.easeInOut(duration: standard)

    /// Snackbar entry/exit.
    static let snackbar = Animation.easeInOut(duration: standard)

    /// Progress bar fill — spring for natural feel.
    static let progressFill = Animation.spring(response: 0.45, dampingFraction: 0.72)

    /// Micro-interactions: like, save, follow confirmations.
    static let microInteraction = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
