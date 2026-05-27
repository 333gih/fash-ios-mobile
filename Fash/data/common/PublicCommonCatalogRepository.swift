import Foundation

/// Public common-service catalog — Android `PublicCommonCatalogRepository`.
final class PublicCommonCatalogRepository {
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 20
        c.timeoutIntervalForResource = 30
        return URLSession(configuration: c)
    }()

    private func localeSegment() -> String {
        AppLocale.coreApiPathSegment()
    }

    private func publicPath(_ pathAfterPublic: String) -> String {
        let rel = pathAfterPublic.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return AppEnvironment.commonServicePath("api/v1/public/\(rel)")
    }

    private func executeGet(_ urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Fash-iOS/1.0", forHTTPHeaderField: "User-Agent")
        let locale = localeSegment()
        req.setValue(locale, forHTTPHeaderField: "Accept-Language")
        req.setValue(locale, forHTTPHeaderField: "X-Fash-Lang")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
        }
        return data
    }

    func getCategoryTree() async -> Result<[CategoryTreeNode], Error> {
        do {
            let data = try await executeGet(publicPath("categories/tree"))
            let obj = try RepositoryHttp.jsonObject(data)
            let arr = obj["categories"] as? [[String: Any]] ?? []
            return .success(arr.map(parseCategoryTreeNode))
        } catch {
            return .failure(error)
        }
    }

    func getBrands(q: String? = nil, offset: Int = 0, limit: Int = 20) async -> Result<BrandsPage, Error> {
        var parts = ["offset=\(max(0, offset))", "limit=\(max(1, limit))"]
        if let q = q?.trimmingCharacters(in: .whitespaces), !q.isEmpty {
            parts.append("q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)")
        }
        do {
            let data = try await executeGet(publicPath("brands") + "?" + parts.joined(separator: "&"))
            let obj = try RepositoryHttp.jsonObject(data)
            let rows = obj["brands"] as? [[String: Any]] ?? obj["items"] as? [[String: Any]] ?? []
            let items = rows.map { o in
                CommonBrandDto(
                    id: RepositoryHttp.optString(o, "id", "ID"),
                    name: RepositoryHttp.optString(o, "name", "Name")
                )
            }
            let total = RepositoryHttp.optInt(obj, "total", default: items.count)
            return .success(BrandsPage(items: items, total: total))
        } catch {
            return .failure(error)
        }
    }

    func getAestheticTags(all: Bool = false, q: String? = nil, offset: Int = 0, limit: Int = 20) async -> Result<[CommonAestheticTagDto], Error> {
        var parts: [String] = []
        if all {
            parts.append("all=true")
        } else {
            parts.append("offset=\(max(0, offset))")
            parts.append("limit=\(max(1, limit))")
            if let q = q?.trimmingCharacters(in: .whitespaces), !q.isEmpty {
                parts.append("q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)")
            }
        }
        let query = parts.isEmpty ? "" : "?" + parts.joined(separator: "&")
        do {
            let data = try await executeGet(publicPath("aesthetic-tags") + query)
            let obj = try RepositoryHttp.jsonObject(data)
            let rows = obj["tags"] as? [[String: Any]] ?? obj["items"] as? [[String: Any]] ?? []
            return .success(rows.map(parseAestheticTag))
        } catch {
            return .failure(error)
        }
    }

    func getCountries(all: Bool = false, q: String? = nil, offset: Int = 0, limit: Int = 20) async -> Result<[CommonCountryDto], Error> {
        var parts: [String] = []
        if all {
            parts.append("all=true")
        } else {
            parts.append("offset=\(max(0, offset))")
            parts.append("limit=\(max(1, limit))")
            if let q = q?.trimmingCharacters(in: .whitespaces), !q.isEmpty {
                parts.append("q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)")
            }
        }
        let query = parts.isEmpty ? "" : "?" + parts.joined(separator: "&")
        do {
            let data = try await executeGet(publicPath("countries") + query)
            let obj = try RepositoryHttp.jsonObject(data)
            let rows = obj["countries"] as? [[String: Any]] ?? obj["items"] as? [[String: Any]] ?? []
            return .success(rows.map(parseCountry))
        } catch {
            return .failure(error)
        }
    }
}

private func parseCategoryTreeNode(_ o: [String: Any]) -> CategoryTreeNode {
    let children = (o["children"] as? [[String: Any]] ?? []).map(parseCategoryTreeNode)
    return CategoryTreeNode(
        id: RepositoryHttp.optString(o, "id", "ID"),
        name: RepositoryHttp.optString(o, "name", "Name"),
        children: children
    )
}

private func parseAestheticTag(_ o: [String: Any]) -> CommonAestheticTagDto {
    CommonAestheticTagDto(
        id: RepositoryHttp.optString(o, "id", "ID"),
        name: RepositoryHttp.optString(o, "name", "Name"),
        displayName: RepositoryHttp.optString(o, "display_name", "displayName", "DisplayName"),
        displayNameVi: RepositoryHttp.optString(o, "display_name_vi", "displayNameVi", "DisplayNameVi")
    )
}

private func parseCountry(_ o: [String: Any]) -> CommonCountryDto {
    CommonCountryDto(
        id: RepositoryHttp.optString(o, "id", "ID"),
        name: RepositoryHttp.optString(o, "name", "Name"),
        iso2: RepositoryHttp.optString(o, "iso2", "ISO2", "iso_2")
    )
}
