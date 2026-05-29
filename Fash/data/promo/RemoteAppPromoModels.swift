import Foundation

struct RemoteAppPromoPayload: Equatable {
    let id: String
    let version: Int
    let title: String
    let description: String
    let imageUrls: [String]
    let badgeLabel: String?
    let primaryButtonLabel: String
    let primaryAction: AppPromoButtonAction
    let secondaryButtonLabel: String?
    let secondaryAction: AppPromoButtonAction?
    let priority: Int
    let scheduleType: String?
}

enum RemoteAppPromoModels {
    static func parseRemoteAppPromoPayload(_ json: [String: Any]) -> RemoteAppPromoPayload? {
        let id = optString(json, "id", "campaign_id", "ID", "CampaignID")
        guard !id.isEmpty else { return nil }
        let version = max(optInt(json, "version", "campaign_version"), 1)
        let title = optString(json, "title", "remote_title", "name", "label")
        let description = optString(json, "description", "body", "detail_body", "message", "remote_message")
        guard !title.isEmpty, !description.isEmpty else { return nil }

        let images = (json["image_urls"] as? [Any] ?? json["imageUrls"] as? [Any] ?? [])
            .compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let primaryObj = (json["primary_button"] as? [String: Any]) ?? (json["primaryButton"] as? [String: Any])
        let primaryLabel = optString(primaryObj ?? [:], "label")
            .nilIfEmpty
            ?? optString(json, "primary_button_label", "primaryButtonLabel").nilIfEmpty
            ?? title
        guard !primaryLabel.isEmpty else { return nil }

        let primaryAction = (primaryObj?["action"] as? [String: Any]).map(parseButtonAction)
            ?? AppPromoButtonAction(
                type: optString(json, "primary_button_action_type"),
                payload: optString(json, "primary_button_payload")
            )

        let secondaryObj = (json["secondary_button"] as? [String: Any]) ?? (json["secondaryButton"] as? [String: Any])
        let secondaryLabel = optString(secondaryObj ?? [:], "label").nilIfEmpty
            ?? optString(json, "secondary_button_label", "secondaryButtonLabel").nilIfEmpty
        let secondaryAction = (secondaryObj?["action"] as? [String: Any]).map(parseButtonAction)

        return RemoteAppPromoPayload(
            id: id,
            version: version,
            title: title,
            description: description,
            imageUrls: images,
            badgeLabel: optStringOrNull(json, "badge_label", "badgeLabel"),
            primaryButtonLabel: primaryLabel,
            primaryAction: primaryAction,
            secondaryButtonLabel: secondaryLabel,
            secondaryAction: secondaryAction,
            priority: optInt(json, "priority"),
            scheduleType: optStringOrNull(json, "schedule_type", "scheduleType")
        )
    }

    static func toAppPromoCampaign(_ payload: RemoteAppPromoPayload) -> AppPromoCampaign {
        AppPromoCampaign(
            campaignId: payload.id,
            version: payload.version,
            kind: .remote,
            remoteTitle: payload.title,
            remoteMessage: payload.description,
            remoteImageUrls: payload.imageUrls,
            remoteBadge: payload.badgeLabel,
            remotePrimaryLabel: payload.primaryButtonLabel,
            remoteSecondaryLabel: payload.secondaryButtonLabel,
            primaryAction: payload.primaryAction,
            secondaryAction: payload.secondaryAction,
            priority: payload.priority,
            scheduleType: payload.scheduleType
        )
    }

    static func sanitizePromoDisplayString(_ value: String?) -> String? {
        let s = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if s.isEmpty || s.lowercased() == "null" { return nil }
        return s
    }

    private static func parseButtonAction(_ obj: [String: Any]) -> AppPromoButtonAction {
        AppPromoButtonAction(
            type: optString(obj, "type"),
            payload: optString(obj, "payload")
        )
    }

    private static func firstNonEmptyString(_ obj: [String: Any], keys: [String]) -> String {
        for key in keys {
            if let raw = obj[key] {
                if raw is NSNull { continue }
                let s = "\(raw)".trimmingCharacters(in: .whitespacesAndNewlines)
                if !s.isEmpty, s.lowercased() != "null" { return s }
            }
        }
        return ""
    }

    private static func optString(_ obj: [String: Any], _ keys: String...) -> String {
        firstNonEmptyString(obj, keys: keys)
    }

    private static func optStringOrNull(_ obj: [String: Any], _ keys: String...) -> String? {
        let s = firstNonEmptyString(obj, keys: keys)
        return s.isEmpty ? nil : s
    }

    private static func optInt(_ obj: [String: Any], _ keys: String...) -> Int {
        for key in keys {
            if let n = obj[key] as? Int { return n }
            if let n = obj[key] as? NSNumber { return n.intValue }
            if let s = obj[key] as? String, let n = Int(s) { return n }
        }
        return 0
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
