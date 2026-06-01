import Foundation

/// Friendly payload rows for notification detail — parity with Android `buildFriendlyPayloadLines`.
enum NotificationDetailPayload {
    enum LineValue: Equatable {
        case plain(String)
        case titleWithId(title: String, id: String)
    }

    enum FriendlyLine: Equatable {
        case text(label: String, value: LineValue)
        case nav(label: String, rawNav: String)
    }

    private static let internalPayloadKeys: Set<String> = [
        "deep_link", "user_notification_id", "inbox_refresh", "title", "body", "channel_id",
        "notification_image_url", "image_url", "detail_body", "rich_body",
        "listing_title", "seller_display_name", "buyer_display_name",
        "follower_display_name", "follower_names_summary", "message_preview",
        "reviewer_display_name", "star_count", "screen", "event", "promo_payload",
        "campaign", "campaign_id", "campaign_version", "image_urls", "badge_label",
        "primary_button", "secondary_button", "primary_button_label", "secondary_button_label",
    ]

    static func buildFriendlyLines(_ item: InboxNotificationItem) -> [FriendlyLine] {
        if NotificationPromoDetail.isAppPromoInboxNotification(item) { return [] }
        guard let data = item.dataMap else { return [] }

        var lines: [FriendlyLine] = []
        func str(_ keys: String...) -> String? {
            NotificationNavigation.firstStringFromDataCi(data, keys)
        }
        func addText(_ label: String, _ value: LineValue) {
            lines.append(.text(label: label, value: value))
        }

        let listingTitle = str("listing_title", "listingTitle")
        let listingId = str("listing_id", "listingId")
        if listingTitle != nil || listingId != nil {
            addText(L10n.notificationDataLabelListing, lineValueTitleOrPlain(title: listingTitle, id: listingId))
        }

        let sellerName = str("seller_display_name", "sellerDisplayName")
        let sellerId = str("seller_user_id", "sellerUserId", "seller_id", "sellerId")
        if sellerName != nil || sellerId != nil {
            addText(L10n.notificationDataLabelSeller, lineValueTitleOrPlain(title: sellerName, id: sellerId))
        }

        if let buyer = str("buyer_display_name", "buyerDisplayName") {
            addText(L10n.notificationDataLabelBuyer, .plain(buyer))
        }

        if let order = str("marketplace_order_id", "order_id", "orderId") {
            addText(L10n.notificationDataLabelOrder, .plain(order))
        }

        let preview = str("message_preview", "messagePreview")
        let conv = str("conversation_id", "conversationId")
        if let preview, let conv {
            addText(L10n.notificationDataLabelChatMessage, .titleWithId(title: preview, id: conv))
        } else if let preview {
            addText(L10n.notificationDataLabelChatMessage, .plain(preview))
        } else if let conv {
            addText(L10n.notificationDataLabelConversation, .plain(conv))
        }

        if let tracking = str("tracking_number", "trackingNumber") {
            addText(L10n.notificationDataLabelTracking, .plain(tracking))
        }

        if let nav = str("nav_target", "navTarget") {
            lines.append(.nav(label: L10n.notificationDataLabelNav, rawNav: nav))
        }

        if let names = str("follower_names_summary", "followerNamesSummary") {
            addText(L10n.notificationDataLabelFollowerBatchNames, .plain(names))
        }

        var followerName = str("follower_display_name", "followerDisplayName")
        if followerName == nil,
           item.payloadType?.lowercased() == "marketplace.follower.new",
           !item.title.isEmpty {
            followerName = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let followerId = str("follower_user_id", "followerUserId")
        if followerName != nil || followerId != nil {
            addText(L10n.notificationDataLabelFollower, lineValueTitleOrPlain(title: followerName, id: followerId))
        }

        if let reviewer = str("reviewer_display_name", "reviewerDisplayName") {
            addText(L10n.notificationDataLabelReviewer, .plain(reviewer))
        }

        if let stars = str("star_count", "starCount"), let n = Int(stars.trimmingCharacters(in: .whitespacesAndNewlines)) {
            addText(L10n.notificationDataLabelRatingStars, .plain("\(n)/5 ★"))
        }

        if let event = str("event") {
            addText(L10n.notificationDataLabelEvent, .plain(event))
        }

        if let type = str("type") {
            let pt = item.payloadType?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if pt.isEmpty || type.lowercased() != pt.lowercased() {
                addText(L10n.notificationDetailPayloadType, .plain(type))
            }
        }

        return lines
    }

    static func buildRawPayloadDump(_ data: [String: Any]?) -> String {
        guard let data, !data.isEmpty else { return "" }
        return data
            .filter { !internalPayloadKeys.contains($0.key.lowercased()) }
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { key, value in
                let disp: String
                switch value {
                case let s as String: disp = s
                case let n as NSNumber: disp = n.stringValue
                case is NSNull: disp = "—"
                default: disp = "\(value)"
                }
                return "\(key): \(disp)"
            }
            .joined(separator: "\n")
    }

    static func navTargetDisplay(_ raw: String) -> String {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "listing": return L10n.notificationDataNavListing
        case "order": return L10n.notificationDataNavOrder
        case "chat": return L10n.notificationDataNavChat
        case "followers_tab": return L10n.notificationDataNavFollowersTab
        case "following_tab": return L10n.notificationDataNavFollowingTab
        case "explore_tab", "explore": return L10n.notificationDataNavExploreTab
        case "": return "—"
        default: return L10n.notificationDataNavGeneric(raw.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private static func lineValueTitleOrPlain(title: String?, id: String?) -> LineValue {
        let t = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let i = id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !t.isEmpty, !i.isEmpty, t.caseInsensitiveCompare(i) == .orderedSame { return .plain(t) }
        if !t.isEmpty, !i.isEmpty { return .titleWithId(title: t, id: i) }
        if !t.isEmpty { return .plain(t) }
        if !i.isEmpty { return .plain(i) }
        return .plain("—")
    }
}

func formatNotificationInstant(_ iso: String) -> String {
    let trimmed = iso.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return iso }
    let parsers: [ISO8601DateFormatter] = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return [withFraction, plain]
    }()
    for parser in parsers {
        if let date = parser.date(from: trimmed) {
            let out = DateFormatter()
            out.locale = Locale(identifier: "vi_VN")
            out.dateFormat = "dd/MM/yyyy HH:mm"
            return out.string(from: date)
        }
    }
    return iso
}
