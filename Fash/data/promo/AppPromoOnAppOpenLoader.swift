import Foundation

/// Fetches admin `on_app_open` promos from core-service catalog and picks one to present.
@MainActor
enum AppPromoOnAppOpenLoader {
    static func fetchAndEnqueue(deps: AppDependencies) async {
        var result = await deps.appPromoInterstitialRepository.fetchActiveCampaigns()
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(400))
            result = await deps.appPromoInterstitialRepository.fetchActiveCampaigns()
        }
        guard case .success(let campaigns) = result else { return }
        for campaign in campaigns where isOnAppOpenSchedule(campaign) {
            AppPromoPendingQueue.enqueue(campaign)
        }
    }

    static func resolvePresentable() -> AppPromoCampaign? {
        guard let remote = AppPromoPendingQueue.pollHighest() else { return nil }
        return AppPromoCampaignStore.canShow(remote) ? remote : nil
    }

    /// Pull catalog, enqueue eligible campaigns, return highest-priority presentable promo.
    static func syncAndResolve(
        deps: AppDependencies,
        isGuestMode: Bool,
        blockBecauseOtherUi: Bool,
        incrementOpenCount: Bool = false
    ) async -> AppPromoCampaign? {
        guard !isGuestMode, !blockBecauseOtherUi else { return nil }
        if incrementOpenCount {
            _ = AppPromoCampaignStore.incrementAppOpenCount()
        }
        await fetchAndEnqueue(deps: deps)
        return resolvePresentable()
    }

    private static func isOnAppOpenSchedule(_ campaign: AppPromoCampaign) -> Bool {
        let type = campaign.scheduleType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return type.isEmpty || type == "on_app_open"
    }
}
