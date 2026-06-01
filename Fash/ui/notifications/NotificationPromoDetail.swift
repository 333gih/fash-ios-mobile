import Foundation

/// Inbox rows created from admin app promo interstitial dispatch (`admin.app_promo_interstitial`).
enum NotificationPromoDetail {
    static func isAppPromoInboxNotification(_ item: InboxNotificationItem) -> Bool {
        let pt = item.payloadType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let dataType = NotificationNavigation.firstStringFromDataCi(item.dataMap, "type")?.lowercased() ?? ""
        return pt == AppPromoPushParsing.adminAppPromoPayloadType
            || dataType == AppPromoPushParsing.adminAppPromoPayloadType
            || NotificationNavigation.firstStringFromDataCi(item.dataMap, "promo_payload", "promoPayload") != nil
    }

    static func parseAppPromoCampaignFromInbox(_ item: InboxNotificationItem) -> AppPromoCampaign? {
        guard let data = item.dataMap else { return nil }

        if let raw = NotificationNavigation.firstStringFromDataCi(data, "promo_payload", "promoPayload"),
           let json = parsePromoJsonObject(raw),
           let payload = RemoteAppPromoModels.parseRemoteAppPromoPayload(json) {
            return RemoteAppPromoModels.toAppPromoCampaign(payload)
        }

        if let campaignRaw = data["campaign"] {
            let raw: String?
            if let s = campaignRaw as? String {
                raw = s.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            } else {
                raw = "\(campaignRaw)".trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            }
            if let raw, let json = parsePromoJsonObject(raw),
               let payload = RemoteAppPromoModels.parseRemoteAppPromoPayload(json) {
                return RemoteAppPromoModels.toAppPromoCampaign(payload)
            }
        }

        guard let id = NotificationNavigation.firstStringFromDataCi(data, "campaign_id", "campaignId", "id") else {
            return nil
        }
        let title = NotificationNavigation.firstStringFromDataCi(data, "title")?.nilIfEmpty ?? item.title
        let description = NotificationNavigation.firstStringFromDataCi(
            data,
            "description",
            "detail_body",
            "detailBody"
        )?.nilIfEmpty ?? item.body
        guard !title.isEmpty, !description.isEmpty else { return nil }

        let images = imageUrlsFromDataMap(data)
        guard let primaryLabel = NotificationNavigation.firstStringFromDataCi(
            data,
            "primary_button_label",
            "primaryButtonLabel"
        ) else { return nil }

        return AppPromoCampaign(
            campaignId: id,
            version: Int(NotificationNavigation.firstStringFromDataCi(data, "campaign_version", "version") ?? "") ?? 1,
            kind: .remote,
            remoteTitle: title,
            remoteMessage: description,
            remoteImageUrls: images,
            remoteBadge: NotificationNavigation.firstStringFromDataCi(data, "badge_label", "badgeLabel"),
            remotePrimaryLabel: primaryLabel,
            remoteSecondaryLabel: NotificationNavigation.firstStringFromDataCi(
                data,
                "secondary_button_label",
                "secondaryButtonLabel"
            ),
            primaryAction: nil,
            secondaryAction: nil
        )
    }

    private static func parsePromoJsonObject(_ raw: String) -> [String: Any]? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return obj
    }

    private static func imageUrlsFromDataMap(_ data: [String: Any]) -> [String] {
        let raw = data["image_urls"] ?? data["imageUrls"]
        switch raw {
        case let arr as [Any]:
            return arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        case let s as String:
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("["),
               let data = t.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                return arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            }
            return t.isEmpty ? [] : [t]
        default:
            return []
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
