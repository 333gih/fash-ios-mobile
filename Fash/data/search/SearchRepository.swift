import Foundation

struct TrendingQueryItem: Hashable {
    let query: String
    let count: Int
}

/// Search API — Android [SearchRepository].
final class SearchRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) { self.client = client }

    func getTrendingTags(limit: Int = 8) async -> Result<[String], Error> {
        await runGetArray(path: "api/v1/search/trending-tags?limit=\(limit.clamped(to: 1...20))")
    }

    func getRecentQueries() async -> Result<[String], Error> {
        await runGetArray(path: "api/v1/search/recent-queries")
    }

    func getTrendingQueries() async -> Result<[TrendingQueryItem], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(relativePath: "api/v1/search/trending-queries", client: client)
            let arr = RepositoryHttp.jsonArray(data)
            let items = arr.compactMap { row -> TrendingQueryItem? in
                let q = RepositoryHttp.optString(row, "query", "Query").trimmingCharacters(in: .whitespaces)
                guard !q.isEmpty else { return nil }
                let count = RepositoryHttp.optInt(row, "count", "Count")
                return TrendingQueryItem(query: q, count: max(0, count))
            }
            return .success(items)
        } catch {
            return .failure(error)
        }
    }

    func autocompleteListingTitles(prefix: String) async -> Result<[String], Error> {
        let trimmed = prefix.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .success([]) }
        let enc = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return await runGetArray(path: "api/v1/search/autocomplete?q=\(enc)")
    }

    func searchListings(
        q: String = "",
        categoryId: String? = nil,
        aestheticTagIds: [String]? = nil,
        sizingMode: String? = nil,
        brandId: String? = nil,
        countryIso2: String? = nil,
        minPrice: Int64? = nil,
        maxPrice: Int64? = nil,
        condition: String? = nil,
        sort: String = "recent",
        limit: Int = 20,
        offset: Int = 0,
        sellerProvinceId: String? = nil,
        sellerDistrictId: String? = nil,
        sellerWardId: String? = nil
    ) async -> Result<[ListingFeedItem], Error> {
        let query = buildListingQuery(
            q: q, categoryId: categoryId, aestheticTagIds: aestheticTagIds, sizingMode: sizingMode,
            brandId: brandId, countryIso2: countryIso2, minPrice: minPrice, maxPrice: maxPrice,
            condition: condition, sort: sort, limit: limit, offset: offset,
            sellerProvinceId: sellerProvinceId, sellerDistrictId: sellerDistrictId, sellerWardId: sellerWardId
        )
        return await runGetFeed(path: "api/v1/search/listings?\(query)")
    }

    func browseListings(
        q: String = "",
        categoryId: String? = nil,
        aestheticTagIds: [String]? = nil,
        brandId: String? = nil,
        countryIso2: String? = nil,
        minPrice: Int64? = nil,
        maxPrice: Int64? = nil,
        condition: String? = nil,
        sort: String = "popular",
        limit: Int = 20,
        offset: Int = 0,
        sellerProvinceId: String? = nil,
        sellerDistrictId: String? = nil,
        sellerWardId: String? = nil
    ) async -> Result<[ListingFeedItem], Error> {
        let query = buildListingQuery(
            q: q, categoryId: categoryId, aestheticTagIds: aestheticTagIds, sizingMode: nil,
            brandId: brandId, countryIso2: countryIso2, minPrice: minPrice, maxPrice: maxPrice,
            condition: condition, sort: sort, limit: limit, offset: offset,
            sellerProvinceId: sellerProvinceId, sellerDistrictId: sellerDistrictId, sellerWardId: sellerWardId
        )
        do {
            let data = try await RepositoryHttp.executeGet(
                urlString: PublicBrowseHttp.publicApiPath("browse/listings") + "?" + query,
                client: client,
                publicBrowse: true
            )
            return .success(try ListingFeedJsonParser.parseFeed(data))
        } catch {
            return .failure(error)
        }
    }

    private func buildListingQuery(
        q: String,
        categoryId: String?,
        aestheticTagIds: [String]?,
        sizingMode: String?,
        brandId: String?,
        countryIso2: String?,
        minPrice: Int64?,
        maxPrice: Int64?,
        condition: String?,
        sort: String,
        limit: Int,
        offset: Int,
        sellerProvinceId: String?,
        sellerDistrictId: String?,
        sellerWardId: String?
    ) -> String {
        func enc(_ s: String) -> String { s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s }
        var parts = ["limit=\(limit)", "offset=\(offset)", "q=\(enc(q))"]
        if let id = categoryId?.trimmingCharacters(in: .whitespaces), !id.isEmpty {
            parts.append("category_id=\(enc(id))")
        }
        let tagCsv = aestheticTagIds?
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .uniqued()
        if let csv = tagCsv, !csv.isEmpty {
            parts.append("aesthetic_tag_ids=\(enc(csv.joined(separator: ",")))")
        }
        if let mode = sizingMode?.trimmingCharacters(in: .whitespaces), !mode.isEmpty, mode.lowercased() != "all" {
            parts.append("sizing_mode=\(enc(mode.lowercased()))")
        }
        if let id = brandId?.trimmingCharacters(in: .whitespaces), !id.isEmpty {
            parts.append("brand_id=\(enc(id))")
        }
        if let iso = countryIso2?.trimmingCharacters(in: .whitespaces).uppercased(), iso.count == 2 {
            parts.append("country_iso2=\(enc(iso))")
        }
        if let min = minPrice { parts.append("min_price=\(min)") }
        if let max = maxPrice { parts.append("max_price=\(max)") }
        if let c = condition?.trimmingCharacters(in: .whitespaces), !c.isEmpty {
            parts.append("condition=\(enc(c))")
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
        parts.append("sort=\(enc(sort))")
        return parts.joined(separator: "&")
    }

    private func runGetFeed(path: String) async -> Result<[ListingFeedItem], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(relativePath: path, client: client)
            return .success(try ListingFeedJsonParser.parseFeed(data))
        } catch {
            return .failure(error)
        }
    }

    private func runGetArray(path: String) async -> Result<[String], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(relativePath: path, client: client)
            return .success(RepositoryHttp.parseStringArray(data))
        } catch {
            return .failure(error)
        }
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
