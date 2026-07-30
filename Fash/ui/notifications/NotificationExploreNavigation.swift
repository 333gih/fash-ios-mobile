import Foundation

/// Parsed from FCM / inbox `data` → Explore overlay filters (mirrors backend exploreNavInput).
struct ExploreNavigationFilter: Equatable {
    var surface: String?
    var seasonKey: String?
    var seasonLabel: String?
    var categoryId: String?
    var brandId: String?
    var aestheticTagId: String?
    var searchQuery: String?

    func hasStructuredFilter() -> Bool {
        !(surface?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
        !(seasonKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
        !(categoryId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
        !(brandId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
        !(aestheticTagId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
        !(searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}

enum NotificationExploreNavigation {
    static let guestActionKey = "fash_guest_action"
    static let guestExploreSurfaceKey = "fash_explore_surface"
    static let guestExploreSeasonLabelKey = "fash_explore_season_label"
    static let guestActionOpenExplore = "open_explore"
    static let guestActionOpenHomeSignup = "open_home_signup"

    private static let exploreNavTargets: Set<String> = ["explore", "explore_tab"]

    static func parseFromNotificationData(_ data: [String: Any]?) -> ExploreNavigationFilter? {
        guard let data, !data.isEmpty else { return nil }
        let nav = firstStringCi(data, "nav_target", "navTarget")?.lowercased() ?? ""
        let feedSurface = firstStringCi(data, "feed_surface", "feedSurface")
        let seasonKey = firstStringCi(data, "season_key", "seasonKey")
        let seasonLabel = firstStringCi(data, "season_label", "seasonLabel")
        let categoryId = firstStringCi(data, "category_id", "categoryId")
        let brandId = firstStringCi(data, "brand_id", "brandId")
        let aestheticTagId = firstStringCi(data, "aesthetic_tag_id", "aestheticTagId")
        let searchQuery = firstStringCi(data, "search_query", "searchQuery")

        let exploreIntent = isExplorePrimaryIntent(data)
        if !exploreIntent, feedSurface == nil, seasonKey == nil { return nil }

        let surface: String? = {
            if let fs = feedSurface, !fs.isEmpty { return fs }
            if nav == "home", let sk = seasonKey, !sk.isEmpty { return "seasonal_near_you" }
            if exploreIntent { return "explore" }
            return nil
        }()

        let filter = ExploreNavigationFilter(
            surface: surface,
            seasonKey: seasonKey,
            seasonLabel: seasonLabel,
            categoryId: categoryId,
            brandId: brandId,
            aestheticTagId: aestheticTagId,
            searchQuery: searchQuery
        )
        if filter.hasStructuredFilter() || exploreIntent { return filter }
        return nil
    }

    static func parseFromStringMap(_ data: [String: String]?) -> ExploreNavigationFilter? {
        guard let data, !data.isEmpty else { return nil }
        var anyMap: [String: Any] = [:]
        for (k, v) in data { anyMap[k] = v }
        return parseFromNotificationData(anyMap)
    }

    static func isExplorePrimaryIntent(_ data: [String: Any]?) -> Bool {
        guard let data, !data.isEmpty else { return false }
        let nav = firstStringCi(data, "nav_target", "navTarget")?.lowercased() ?? ""
        if exploreNavTargets.contains(nav) { return true }
        let feedSurface = firstStringCi(data, "feed_surface", "feedSurface")?.lowercased() ?? ""
        if nav == "home", feedSurface == "seasonal_near_you" { return true }
        let ptype = firstStringCi(data, "type", "payload_type", "payloadType")?.lowercased() ?? ""
        if ptype.contains("season_shift") { return true }
        if ptype.contains("community_quiet") { return true }
        if ptype.contains("style_drought") { return true }
        if ptype.contains("style_fresh") { return true }
        if ptype.contains("hunt_today") { return true }
        return false
    }

    static func parseFromGuestPayload(_ data: [String: String]) -> ExploreNavigationFilter? {
        let action = data[guestActionKey]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard action == guestActionOpenExplore else { return nil }
        let surface = data[guestExploreSurfaceKey]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let seasonLabel = data[guestExploreSeasonLabelKey]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return ExploreNavigationFilter(
            surface: (surface?.isEmpty == false) ? surface : "explore",
            seasonLabel: (seasonLabel?.isEmpty == false) ? seasonLabel : nil
        )
    }

    private static func firstStringCi(_ data: [String: Any], _ keys: String...) -> String? {
        let byLower = Dictionary(uniqueKeysWithValues: data.map { ($0.key.lowercased(), $0.value) })
        for key in keys {
            guard let value = byLower[key.lowercased()] else { continue }
            let trimmed: String
            switch value {
            case let s as String:
                trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            case let n as NSNumber:
                trimmed = n.stringValue
            default:
                trimmed = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}
