import Foundation

struct AppAdvertisingSlideItem: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let bannerImageUrl: String
    let stylePreset: String
    let contentType: String
    let advertiserScope: String
    let partnerDisclosure: String
    let badgeLabel: String
    let navigationType: String
    let navigationPayload: String
}

struct AppAdvertisingSlidesResponse: Equatable {
    let placementKey: String
    let items: [AppAdvertisingSlideItem]
}

enum AppAdvertisingSlidesParser {
    static func parse(_ raw: String) throws -> AppAdvertisingSlidesResponse {
        let data = Data(raw.utf8)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let placement = (root["placement_key"] as? String)?.trimmingCharacters(in: .whitespaces) ?? "promo_slider_main"
        let arr = root["items"] as? [[String: Any]] ?? []
        let items: [AppAdvertisingSlideItem] = arr.compactMap { o in
            let nav = o["navigation"] as? [String: Any]
            let navType = (nav?["type"] as? String)?.trimmingCharacters(in: .whitespaces)
                ?? (o["navigation_type"] as? String)?.trimmingCharacters(in: .whitespaces)
                ?? "none"
            let navPayload = (nav?["payload"] as? String)?.trimmingCharacters(in: .whitespaces)
                ?? (o["navigation_payload"] as? String)?.trimmingCharacters(in: .whitespaces)
                ?? ""
            return AppAdvertisingSlideItem(
                id: (o["id"] as? String) ?? "",
                title: (o["title"] as? String) ?? "",
                subtitle: (o["subtitle"] as? String) ?? "",
                bannerImageUrl: (o["banner_image_url"] as? String) ?? "",
                stylePreset: (o["style_preset"] as? String)?.trimmingCharacters(in: .whitespaces).isEmpty == false
                    ? (o["style_preset"] as? String)! : "gradient_primary",
                contentType: (o["content_type"] as? String) ?? "announcement",
                advertiserScope: (o["advertiser_scope"] as? String) ?? "platform",
                partnerDisclosure: (o["partner_disclosure"] as? String) ?? "",
                badgeLabel: (o["badge_label"] as? String) ?? "",
                navigationType: navType,
                navigationPayload: navPayload
            )
        }
        return AppAdvertisingSlidesResponse(placementKey: placement, items: items)
    }
}
