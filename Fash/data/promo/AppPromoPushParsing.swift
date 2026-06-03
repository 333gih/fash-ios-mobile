import Foundation

/// Port of Android `AppPromoPushParsing` (data.promo).
enum AppPromoPushParsing {
    static let adminAppPromoPayloadType = "admin.app_promo_interstitial"

    static func isAppPromoPushData(_ data: [String: String]?) -> Bool {
        guard let data, !data.isEmpty else { return false }
        let type = data["type"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return type == adminAppPromoPayloadType || !(data["promo_payload"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    static func parseAppPromoFromPushData(
        data: [String: String],
        fallbackTitle: String? = nil,
        fallbackBody: String? = nil
    ) -> AppPromoCampaign? {
        let raw = data["promo_payload"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !raw.isEmpty,
           let jsonData = raw.data(using: .utf8),
           let obj = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any],
           let payload = RemoteAppPromoModels.parseRemoteAppPromoPayload(obj) {
            return RemoteAppPromoModels.toAppPromoCampaign(payload)
        }

        let id = data["campaign_id"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = data["title"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? fallbackTitle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? ""
        let body = data["body"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? data["detail_body"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? fallbackBody?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? ""
        guard !id.isEmpty, !title.isEmpty, !body.isEmpty else { return nil }
        let version = max(Int(data["campaign_version"] ?? "") ?? 1, 1)
        let images = imageUrlsFromPushData(data)
        return AppPromoCampaign(
            campaignId: id,
            version: version,
            kind: .remote,
            remoteTitle: title,
            remoteMessage: body,
            remoteImageUrls: images,
            remotePrimaryLabel: title,
            primaryAction: AppPromoButtonAction(type: "none", payload: "")
        )
    }

    private static func imageUrlsFromPushData(_ data: [String: String]) -> [String] {
        if let raw = data["image_urls"]?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            if raw.hasPrefix("["),
               let jsonData = raw.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: jsonData) as? [Any] {
                return arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
            return [raw]
        }
        return []
    }

    static func parseRealtimeCampaignJson(_ campaignJson: String) -> AppPromoCampaign? {
        guard let data = campaignJson.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let payload = RemoteAppPromoModels.parseRemoteAppPromoPayload(obj) else { return nil }
        return RemoteAppPromoModels.toAppPromoCampaign(payload)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
