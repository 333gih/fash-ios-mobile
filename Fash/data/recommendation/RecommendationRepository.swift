import Foundation

struct HomeRecommendationSections: Equatable {
    var huntToday: [ListingFeedItem] = []
    var forYou: [ListingFeedItem] = []
    var stylePicks: [ListingFeedItem] = []
    var continueBrowsing: [ListingFeedItem] = []
    var similarToSaved: [ListingFeedItem] = []
}

/// Personalized discovery — Android [RecommendationRepository].
final class RecommendationRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) { self.client = client }

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
        sellerWardId: String? = nil
    ) async -> Result<[ListingFeedItem], Error> {
        var parts = ["limit=\(limit)", "offset=\(offset)"]
        func enc(_ s: String) -> String { s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s }
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
        sectionLimit: Int = 12
    ) async -> Result<HomeRecommendationSections, Error> {
        let query = "hunt_today_limit=\(huntTodayLimit)&for_you_limit=\(forYouLimit)&section_limit=\(sectionLimit)"
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
                huntToday: parseSectionItems(payload, key: "hunt_today"),
                forYou: parseSectionItems(payload, key: "for_you"),
                stylePicks: parseSectionItems(payload, key: "style_picks"),
                continueBrowsing: parseSectionItems(payload, key: "continue_browsing"),
                similarToSaved: parseSectionItems(payload, key: "similar_to_saved")
            ))
        } catch {
            return .failure(error)
        }
    }

    private func parseSectionItems(_ obj: [String: Any], key: String) -> [ListingFeedItem] {
        guard let arr = obj[key] as? [[String: Any]] else { return [] }
        return arr.compactMap { row in
            guard let id = (row["id"] as? String) ?? (row["listing_id"] as? String) else { return nil }
            let title = row["title"] as? String ?? row["name"] as? String ?? ""
            let price = (row["price"] as? NSNumber)?.int64Value ?? 0
            let imageURL = (row["thumbnail_url"] as? String)
                ?? ((row["image_urls"] as? [String])?.first)
            let seller = (row["seller"] as? [String: Any])?["username"] as? String
            return ListingFeedItem(id: id, title: title, price: price, imageURL: imageURL, sellerUsername: seller)
        }
    }
}
