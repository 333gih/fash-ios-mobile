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
        while true {
            guard let remote = AppPromoPendingQueue.pollHighest() else { return nil }
            if AppPromoCampaignStore.isDialogConsumed(remote) { continue }
            if AppPromoCampaignStore.canShow(remote) {
                return remote
            }
        }
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
        if let remote = resolvePresentable() { return remote }
        if let slide = await slideFallback(deps: deps) { return slide }
        return AppPromoDefaultFallback.resolve()
    }

    private static func slideFallback(deps: AppDependencies) async -> AppPromoCampaign? {
        let result = await deps.advertisingRepository.getSlides(placement: "promo_slider_main")
        guard case .success(let parsed) = result, let slide = parsed.items.first else { return nil }
        guard let campaign = AppPromoSlideFallback.fromSlide(slide) else { return nil }
        return AppPromoCampaignStore.canShow(campaign) ? campaign : nil
    }

    private static func isOnAppOpenSchedule(_ campaign: AppPromoCampaign) -> Bool {
        let type = campaign.scheduleType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return type.isEmpty || type == "on_app_open"
    }
}
