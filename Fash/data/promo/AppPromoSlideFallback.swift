import Foundation

/// When admin interstitial catalog is empty, derive a Shopee-style app-open dialog
/// from the first live promo carousel slide (`promo_slider_main`).
enum AppPromoSlideFallback {
    private static let idPrefix = "promo_slide_"
    private static let version = 1
    private static let priority = 50
    private static let maxShowsPerUser = 7
    private static let cooldownHours = 4

    static func fromSlide(_ slide: AppAdvertisingSlideItem) -> AppPromoCampaign? {
        let id = slide.id.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = slide.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = slide.subtitle.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? title
        guard !id.isEmpty, !title.isEmpty else { return nil }
        let images: [String] = {
            let url = slide.bannerImageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            return url.isEmpty ? [] : [url]
        }()
        return AppPromoCampaign(
            campaignId: "\(idPrefix)\(id)",
            version: version,
            kind: .remote,
            remoteTitle: title,
            remoteMessage: message,
            remoteImageUrls: images,
            remoteBadge: slide.badgeLabel.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            remotePrimaryLabel: title,
            remoteSecondaryLabel: nil,
            primaryAction: AppPromoButtonAction(
                type: slide.navigationType.isEmpty ? "in_app_explore" : slide.navigationType,
                payload: slide.navigationPayload
            ),
            priority: priority,
            scheduleType: "on_app_open",
            maxShowsPerUser: maxShowsPerUser,
            cooldownHours: cooldownHours
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
