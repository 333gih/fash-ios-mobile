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
        isGuestMode: Bool,
        progress: LaunchWaitingProgress
    ) async {
        let exploreSteps = exploreVM.items.isEmpty ? 5 : 4
        let homeSteps = isGuestMode ? 3 : 7
        progress.beginWarmup(homeSteps: homeSteps, exploreSteps: exploreSteps)

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await performWarmup(
                    deps: deps,
                    homeVM: homeVM,
                    exploreVM: exploreVM,
                    isGuestMode: isGuestMode,
                    progress: progress
                )
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(maximumWaitSeconds))
            }
            _ = await group.next()
            group.cancelAll()
        }
        progress.complete()
    }

    private static func performWarmup(
        deps: AppDependencies,
        homeVM: HomeViewModel,
        exploreVM: ExploreViewModel,
        isGuestMode: Bool,
        progress: LaunchWaitingProgress
    ) async {
        async let home: Void = homeVM.loadShell(
            deps: deps,
            isGuestMode: isGuestMode,
            launchProgress: progress
        )
        async let explore: Void = exploreVM.warmLaunchCaches(
            deps: deps,
            isGuestMode: isGuestMode,
            launchProgress: progress
        )
        _ = await (home, explore)
    }
}
