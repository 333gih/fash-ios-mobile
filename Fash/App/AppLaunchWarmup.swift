import Foundation

/// Cold-start prefetch for Home + Explore + main shell tabs before the main UI is shown.
///
/// Runs network work in parallel with a hard timeout so the waiting screen never blocks indefinitely.
/// Individual requests still degrade gracefully inside the view models (empty sections on failure).
@MainActor
enum AppLaunchWarmup {
    /// Minimum branded splash time — matches [RootView] / Android `SPLASH_DISPLAY_MS`.
    static let minimumDisplaySeconds: TimeInterval = 2.5
    /// Upper bound so a slow network cannot trap the user on the waiting screen.
    static let maximumWaitSeconds: TimeInterval = 12

    static func run(
        deps: AppDependencies,
        homeVM: HomeViewModel,
        exploreVM: ExploreViewModel,
        profileVM: ProfileViewModel,
        chatVM: ChatViewModel,
        ordersVM: OrdersViewModel,
        isGuestMode: Bool,
        progress: LaunchWaitingProgress
    ) async {
        let exploreSteps = exploreVM.items.isEmpty ? 5 : 4
        let homeSteps = isGuestMode ? 3 : 7
        let shellSteps = isGuestMode ? 0 : 3
        progress.beginWarmup(homeSteps: homeSteps, exploreSteps: exploreSteps, shellSteps: shellSteps)

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await performWarmup(
                    deps: deps,
                    homeVM: homeVM,
                    exploreVM: exploreVM,
                    profileVM: profileVM,
                    chatVM: chatVM,
                    ordersVM: ordersVM,
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
        profileVM: ProfileViewModel,
        chatVM: ChatViewModel,
        ordersVM: OrdersViewModel,
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
        async let shell: Void = warmShellTabs(
            deps: deps,
            profileVM: profileVM,
            chatVM: chatVM,
            ordersVM: ordersVM,
            isGuestMode: isGuestMode,
            progress: progress
        )
        _ = await (home, explore, shell)
    }

    private static func warmShellTabs(
        deps: AppDependencies,
        profileVM: ProfileViewModel,
        chatVM: ChatViewModel,
        ordersVM: OrdersViewModel,
        isGuestMode: Bool,
        progress: LaunchWaitingProgress
    ) async {
        guard !isGuestMode else { return }
        async let profile: Void = {
            await profileVM.refresh(deps: deps, force: true)
            progress.completeShellStep()
        }()
        async let chat: Void = {
            await chatVM.loadConversations(deps: deps)
            progress.completeShellStep()
        }()
        async let orders: Void = {
            await ordersVM.refresh(deps: deps)
            progress.completeShellStep()
        }()
        _ = await (profile, chat, orders)
    }
}
