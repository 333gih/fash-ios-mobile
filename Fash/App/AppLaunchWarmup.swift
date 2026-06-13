import Foundation

/// Cold-start prefetch — gate on Home feed only; Explore and shell tabs load in the background.
@MainActor
enum AppLaunchWarmup {
    /// Short branded splash floor (no progress UI).
    static let minimumDisplaySeconds: TimeInterval = 0.75
    /// Home feed gate — never trap the user longer than this on the waiting screen.
    static let homeGateMaxSeconds: TimeInterval = 6

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
        progress.beginWarmup(homeSteps: 4, exploreSteps: 0, shellSteps: 0)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await homeVM.awaitLaunchReady(
                    deps: deps,
                    isGuestMode: isGuestMode,
                    launchProgress: progress
                )
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(homeGateMaxSeconds))
            }
            _ = await group.next()
            group.cancelAll()
        }
        progress.complete()

        scheduleDeferredWarmup(
            deps: deps,
            exploreVM: exploreVM,
            profileVM: profileVM,
            chatVM: chatVM,
            ordersVM: ordersVM,
            isGuestMode: isGuestMode
        )
    }

    /// Explore + profile/chat/orders — after main shell is visible.
    private static func scheduleDeferredWarmup(
        deps: AppDependencies,
        exploreVM: ExploreViewModel,
        profileVM: ProfileViewModel,
        chatVM: ChatViewModel,
        ordersVM: OrdersViewModel,
        isGuestMode: Bool
    ) {
        Task(priority: .utility) { @MainActor in
            async let explore: Void = exploreVM.warmLaunchCaches(
                deps: deps,
                isGuestMode: isGuestMode,
                launchProgress: nil
            )
            async let shell: Void = warmShellTabs(
                deps: deps,
                profileVM: profileVM,
                chatVM: chatVM,
                ordersVM: ordersVM,
                isGuestMode: isGuestMode
            )
            _ = await (explore, shell)
        }
    }

    private static func warmShellTabs(
        deps: AppDependencies,
        profileVM: ProfileViewModel,
        chatVM: ChatViewModel,
        ordersVM: OrdersViewModel,
        isGuestMode: Bool
    ) async {
        guard !isGuestMode else { return }
        async let profile: Void = profileVM.refreshIfStale(deps: deps)
        async let chat: Void = chatVM.loadConversationsWhenNeeded(deps: deps)
        _ = await (profile, chat)
        if ordersVM.buyingOrders.isEmpty, ordersVM.sellingOrders.isEmpty {
            await ordersVM.refresh(deps: deps)
        }
    }
}
