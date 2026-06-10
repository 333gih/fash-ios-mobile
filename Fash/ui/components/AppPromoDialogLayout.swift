import CoreGraphics
import Foundation

/// Resolved promo card content — drives which blocks render and hero sizing.
struct AppPromoDialogLayout {
    let title: String
    let message: String?
    let primaryLabel: String
    let secondaryLabel: String?
    let badge: String?
    let imageUrls: [String]
    let showImageHero: Bool
    let showIconHero: Bool
    let iconHeroKind: AppPromoCampaignKind

    var showTitle: Bool { !title.isEmpty }
    var showMessage: Bool { !(message?.isEmpty ?? true) }
    var showBadgeOnHero: Bool { badge != nil && (showImageHero || showIconHero) }
    var showBadgeInline: Bool { badge != nil && !showBadgeOnHero }
    var showSecondary: Bool { !(secondaryLabel?.isEmpty ?? true) }

    func heroHeight(cardWidth: CGFloat) -> CGFloat? {
        if showImageHero {
            return min(max(cardWidth * 0.52, 120), 200)
        }
        if showIconHero { return 88 }
        return nil
    }

    static func resolve(campaign: AppPromoCampaign) -> AppPromoDialogLayout? {
        let title = RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteTitle) ?? ""
        let message = RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteMessage)
        let primary = RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remotePrimaryLabel)
            ?? L10n.appPromoRatingPrimary
        guard !title.isEmpty, !primary.isEmpty else { return nil }

        let images = campaign.remoteImageUrls
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let showImageHero = campaign.kind == .remote && !images.isEmpty
        let showIconHero = !showImageHero && campaign.kind != .remote

        let secondary = RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteSecondaryLabel)
            ?? (campaign.kind == .remote ? nil : L10n.appPromoSecondaryLater)

        return AppPromoDialogLayout(
            title: title,
            message: message,
            primaryLabel: primary,
            secondaryLabel: secondary,
            badge: RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteBadge),
            imageUrls: images,
            showImageHero: showImageHero,
            showIconHero: showIconHero,
            iconHeroKind: campaign.kind
        )
    }
}
