import Foundation

/// Port of Android `AppPromoPushParsing` (data.promo).
enum AppPromoPushParsing {
    static let adminAppPromoPayloadType = "admin.app_promo_interstitial"

    struct ParsedCampaign: Equatable {
        let id: String
        let version: Int
        let title: String
        let body: String
    }

    static func isAppPromoPushData(_ data: [String: String]?) -> Bool {
        guard let data, !data.isEmpty else { return false }
        let type = data["type"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return type == adminAppPromoPayloadType || !(data["promo_payload"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    static func parseAppPromoFromPushData(
        data: [String: String],
        fallbackTitle: String? = nil,
        fallbackBody: String? = nil
    ) -> ParsedCampaign? {
        let raw = data["promo_payload"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !raw.isEmpty,
           let jsonData = raw.data(using: .utf8),
           let obj = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any],
           let parsed = parseRemoteCampaignObject(obj) {
            return parsed
        }

        let id = data["campaign_id"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = (data["title"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? fallbackTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "")
        let body = (data["body"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? data["detail_body"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? fallbackBody?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "")
        guard !id.isEmpty, !title.isEmpty, !body.isEmpty else { return nil }
        let version = max(Int(data["campaign_version"] ?? "") ?? 1, 1)
        return ParsedCampaign(id: id, version: version, title: title, body: body)
    }

    static func parseRealtimeCampaignJson(_ campaignJson: String) -> ParsedCampaign? {
        guard let data = campaignJson.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        return parseRemoteCampaignObject(obj)
    }

    private static func parseRemoteCampaignObject(_ obj: [String: Any]) -> ParsedCampaign? {
        let campaign = (obj["campaign"] as? [String: Any]) ?? obj
        let id = firstString(campaign, keys: ["campaign_id", "id", "ID"])
        let title = firstString(campaign, keys: ["title", "remote_title", "name", "label"])
        let body = firstString(campaign, keys: ["message", "body", "detail_body", "remote_message", "description"])
        guard !id.isEmpty, !title.isEmpty, !body.isEmpty else { return nil }
        let version: Int = {
            if let n = campaign["campaign_version"] as? NSNumber { return max(n.intValue, 1) }
            if let n = campaign["version"] as? NSNumber { return max(n.intValue, 1) }
            return 1
        }()
        return ParsedCampaign(id: id, version: version, title: title, body: body)
    }

    private static func firstString(_ obj: [String: Any], keys: [String]) -> String {
        for key in keys {
            if let str = (obj[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                return str
            }
        }
        return ""
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
