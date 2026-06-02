import Foundation

struct HomeRecommendationSections: Equatable {
    var huntToday: [ListingFeedItem] = []
    var forYou: [ListingFeedItem] = []
    var stylePicks: [ListingFeedItem] = []
    var continueBrowsing: [ListingFeedItem] = []
    var similarToSaved: [ListingFeedItem] = []
    var seasonalNearYou: [ListingFeedItem] = []
    var shoppingContext: ShoppingContext?
}

/// Personalized discovery — Android [RecommendationRepository].
final class RecommendationRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) { self.client = client }

    private func enc(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }

    func exploreListings(
        publicBrowse: Bool,
        categoryId: String? = nil,
        aestheticTagIds: [String]? = nil,
        brandId: String? = nil,
        minPrice: Int64? = nil,
        maxPrice: Int64? = nil,
        condition: String? = nil,
        countryIso2: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        sizingMode: String? = nil,
        sellerProvinceId: String? = nil,
        sellerDistrictId: String? = nil,
        sellerWardId: String? = nil,
        surface: String? = nil,
        excludeListingIds: [String]? = nil
    ) async -> Result<[ListingFeedItem], Error> {
        var parts = ["limit=\(limit)", "offset=\(offset)"]
        if let id = categoryId?.trimmingCharacters(in: .whitespaces), !id.isEmpty {
            parts.append("category_id=\(enc(id))")
        }
        let tagCsv = aestheticTagIds?
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if let csv = tagCsv, !csv.isEmpty {
            parts.append("aesthetic_tag_ids=\(enc(csv.joined(separator: ",")))")
        }
        if let id = brandId?.trimmingCharacters(in: .whitespaces), !id.isEmpty {
            parts.append("brand_id=\(enc(id))")
        }
        if let min = minPrice { parts.append("min_price=\(min)") }
        if let max = maxPrice { parts.append("max_price=\(max)") }
        if let c = condition?.trimmingCharacters(in: .whitespaces), !c.isEmpty {
            parts.append("condition=\(enc(c))")
        }
        if let iso = countryIso2?.trimmingCharacters(in: .whitespaces).uppercased(), iso.count == 2 {
            parts.append("country_iso2=\(enc(iso))")
        }
        if let mode = sizingMode?.trimmingCharacters(in: .whitespaces), !mode.isEmpty, mode.lowercased() != "all" {
            parts.append("sizing_mode=\(enc(mode.lowercased()))")
        }
        if let id = sellerProvinceId?.trimmingCharacters(in: .whitespaces), !id.isEmpty {
            parts.append("seller_province_id=\(enc(id))")
        }
        if let id = sellerDistrictId?.trimmingCharacters(in: .whitespaces), !id.isEmpty {
            parts.append("seller_district_id=\(enc(id))")
        }
        if let id = sellerWardId?.trimmingCharacters(in: .whitespaces), !id.isEmpty {
            parts.append("seller_ward_id=\(enc(id))")
        }
        if let surf = surface?.trimmingCharacters(in: .whitespaces), !surf.isEmpty {
            parts.append("surface=\(enc(surf))")
        }
        let excludeCsv = excludeListingIds?
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if let csv = excludeCsv, !csv.isEmpty {
            parts.append("exclude_listing_ids=\(enc(Array(Set(csv)).joined(separator: ",")))")
        }
        let query = parts.joined(separator: "&")
        do {
            let data: Data
            if publicBrowse {
                data = try await RepositoryHttp.executeGet(
                    urlString: PublicBrowseHttp.publicApiPath("browse/recommendations/explore-listings") + "?" + query,
                    client: client,
                    publicBrowse: true
                )
            } else {
                data = try await RepositoryHttp.executeCoreGet(
                    relativePath: "api/v1/recommendations/explore-listings?\(query)",
                    client: client
                )
            }
            return .success(try ListingFeedJsonParser.parseFeed(data))
        } catch {
            return .failure(error)
        }
    }

    func homeSections(
        publicBrowse: Bool,
        huntTodayLimit: Int = 12,
        forYouLimit: Int = 16,
        sectionLimit: Int = 12,
        sizingMode: String? = nil
    ) async -> Result<HomeRecommendationSections, Error> {
        var parts = [
            "hunt_today_limit=\(huntTodayLimit)",
            "for_you_limit=\(forYouLimit)",
            "section_limit=\(sectionLimit)",
        ]
        if let mode = sizingMode?.trimmingCharacters(in: .whitespaces), !mode.isEmpty, mode.lowercased() != "all" {
            parts.append("sizing_mode=\(enc(mode.lowercased()))")
        }
        let query = parts.joined(separator: "&")
        do {
            let data: Data
            if publicBrowse {
                data = try await RepositoryHttp.executeGet(
                    urlString: PublicBrowseHttp.publicApiPath("browse/recommendations/home-sections") + "?" + query,
                    client: client,
                    publicBrowse: true
                )
            } else {
                data = try await RepositoryHttp.executeCoreGet(
                    relativePath: "api/v1/recommendations/home-sections?\(query)",
                    client: client
                )
            }
            let root = try RepositoryHttp.jsonObject(data)
            let payload = (root["data"] as? [String: Any]) ?? root
            return .success(HomeRecommendationSections(
                huntToday: ListingFeedJsonParser.parseItemsArray(payload["hunt_today"] as? [[String: Any]]),
                forYou: ListingFeedJsonParser.parseItemsArray(payload["for_you"] as? [[String: Any]]),
                stylePicks: ListingFeedJsonParser.parseItemsArray(payload["style_picks"] as? [[String: Any]]),
                continueBrowsing: ListingFeedJsonParser.parseItemsArray(payload["continue_browsing"] as? [[String: Any]]),
                similarToSaved: ListingFeedJsonParser.parseItemsArray(payload["similar_to_saved"] as? [[String: Any]]),
                seasonalNearYou: ListingFeedJsonParser.parseItemsArray(payload["seasonal_near_you"] as? [[String: Any]]),
                shoppingContext: ShoppingContext.fromDict(payload["shopping_context"] as? [String: Any])
            ))
        } catch {
            return .failure(error)
        }
    }

    func recordFeedEvents(
        publicBrowse: Bool,
        sessionId: String,
        events: [FeedEventPayload]
    ) async -> Result<Void, Error> {
        guard !events.isEmpty else { return .success(()) }
        var arr: [[String: Any]] = []
        for event in events.prefix(50) {
            var obj: [String: Any] = [
                "listing_id": event.listingId,
                "surface": event.surface,
                "event_type": event.eventType,
                "position": event.position,
            ]
            if let dwell = event.dwellMs { obj["dwell_ms"] = dwell }
            if let experimentId = event.experimentId { obj["experiment_id"] = experimentId }
            arr.append(obj)
        }
        let body: [String: Any] = [
            "session_id": sessionId,
            "events": arr,
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            if publicBrowse {
                try await RepositoryHttp.executePost(
                    urlString: PublicBrowseHttp.publicApiPath("browse/recommendations/feed-events"),
                    client: client,
                    body: data,
                    publicBrowse: true
                )
            } else {
                try await RepositoryHttp.executeCorePost(
                    relativePath: "api/v1/recommendations/feed-events",
                    client: client,
                    body: data
                )
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func shoppingContext(publicBrowse: Bool) async -> Result<ShoppingContext, Error> {
        do {
            let data: Data
            if publicBrowse {
                data = try await RepositoryHttp.executeGet(
                    urlString: PublicBrowseHttp.publicApiPath("browse/recommendations/context"),
                    client: client,
                    publicBrowse: true
                )
            } else {
                data = try await RepositoryHttp.executeCoreGet(
                    relativePath: "api/v1/recommendations/context",
                    client: client
                )
            }
            let root = try RepositoryHttp.jsonObject(data)
            let payload = (root["data"] as? [String: Any]) ?? root
            return .success(ShoppingContext.fromDict(payload) ?? ShoppingContext())
        } catch {
            return .failure(error)
        }
    }

    func uxPersonalization(clientHour: Int? = nil) async -> Result<UxPersonalizationBundle, Error> {
        var path = "api/v1/recommendations/ux-personalization"
        if let hour = clientHour {
            path += "?client_hour=\(hour)"
        }
        do {
            let data = try await RepositoryHttp.executeCoreGet(relativePath: path, client: client)
            return .success(try parseUxPersonalization(data))
        } catch {
            return .failure(error)
        }
    }

    func recordUxEvents(events: [UxEventPayload]) async -> Result<Void, Error> {
        guard !events.isEmpty else { return .success(()) }
        var arr: [[String: Any]] = []
        for event in events.prefix(50) {
            var obj: [String: Any] = [
                "scope": event.scope,
                "tab_key": event.tabKey,
            ]
            if let hour = event.clientHour { obj["client_hour"] = hour }
            if let dwell = event.dwellMs { obj["dwell_ms"] = dwell }
            arr.append(obj)
        }
        let body: [String: Any] = ["events": arr]
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            try await RepositoryHttp.executeCorePost(
                relativePath: "api/v1/recommendations/ux-events",
                client: client,
                body: data
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func parseUxPersonalization(_ data: Data) throws -> UxPersonalizationBundle {
        let root = try RepositoryHttp.jsonObject(data)
        let payload = (root["data"] as? [String: Any]) ?? root
        let home = (payload["home"] as? [String: Any]) ?? [:]
        let profile = (payload["profile"] as? [String: Any]) ?? [:]
        let shortcutObj = home["explore_shortcut"] as? [String: Any]
        let shortcut = shortcutObj.map { obj in
            HomeExploreShortcut(
                labelKey: RepositoryHttp.optString(obj, "label_key"),
                aestheticTagId: RepositoryHttp.optString(obj, "aesthetic_tag_id").nilIfEmpty,
                aestheticTagName: RepositoryHttp.optString(obj, "aesthetic_tag_name").nilIfEmpty,
                categoryId: RepositoryHttp.optString(obj, "category_id").nilIfEmpty,
                brandId: RepositoryHttp.optString(obj, "brand_id").nilIfEmpty
            )
        }
        var sectionLimits: [String: Int] = [:]
        if let limits = home["section_limits"] as? [String: Any] {
            for (key, value) in limits {
                if let n = value as? NSNumber { sectionLimits[key] = n.intValue }
            }
        }
        return UxPersonalizationBundle(
            home: HomeUxPersonalization(
                defaultTabKey: RepositoryHttp.optString(home, "default_tab").nilIfEmpty ?? HomeFeedTabKeys.huntToday,
                tabOrder: stringArray(home["tab_order"]),
                prefetchTabs: stringArray(home["prefetch_tabs"]),
                sectionLimits: sectionLimits,
                exploreShortcut: shortcut
            ),
            profile: ProfileUxPersonalization(
                defaultTabKey: RepositoryHttp.optString(profile, "default_tab_key").nilIfEmpty ?? ProfileTabKeys.selling,
                tabOrderKeys: stringArray(profile["tab_order_keys"]),
                primaryMode: RepositoryHttp.optString(profile, "primary_mode").nilIfEmpty ?? "balanced"
            )
        )
    }

    private func stringArray(_ value: Any?) -> [String] {
        guard let arr = value as? [Any] else { return [] }
        return arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
