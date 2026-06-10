import Foundation

/// In-memory guard so the same promo is not shown twice in one app process.
enum AppPromoSessionStore {
    private static var consumedDialogKeys = Set<String>()

    private static func sessionKey(campaignId: String, version: Int) -> String {
        "\(campaignId)_v\(version)"
    }

    static func isDialogConsumed(_ campaign: AppPromoCampaign) -> Bool {
        consumedDialogKeys.contains(sessionKey(campaignId: campaign.campaignId, version: campaign.version))
    }

    static func markDialogConsumed(_ campaign: AppPromoCampaign) {
        consumedDialogKeys.insert(sessionKey(campaignId: campaign.campaignId, version: campaign.version))
    }
}
