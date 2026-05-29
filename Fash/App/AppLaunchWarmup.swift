import Foundation

/// Cold-start prefetch for Home + Explore before the main shell is shown.
///
/// Runs network work in parallel with a hard timeout so the waiting screen never blocks indefinitely.
/// Individual requests still degrade gracefully inside the view models (empty sections on failure).
@MainActor
enum AppLaunchWarmup {
    /// Minimum branded splash time — matches [RootView] / Android `SPLASH_DISPLAY_MS`.
    static let minimumDisplaySeconds: TimeInterval = 2.5
    /// Upper bound so a slow network cannot trap the user on the waiting screen.
    static let maximumWaitSeconds: TimeInterval = 10

    static func run(
        deps: AppDependencies,
        homeVM: HomeViewModel,
        exploreVM: ExploreViewModel,
        isGuestMode: Bool
    ) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await performWarmup(deps: deps, homeVM: homeVM, exploreVM: exploreVM, isGuestMode: isGuestMode)
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(maximumWaitSeconds))
            }
            _ = await group.next()
            group.cancelAll()
        }
    }

    private static func performWarmup(
        deps: AppDependencies,
        homeVM: HomeViewModel,
        exploreVM: ExploreViewModel,
        isGuestMode: Bool
    ) async {
        async let home: Void = homeVM.loadShell(deps: deps, isGuestMode: isGuestMode)
        async let explore: Void = exploreVM.warmLaunchCaches(deps: deps, isGuestMode: isGuestMode)
        _ = await (home, explore)
    }
}
