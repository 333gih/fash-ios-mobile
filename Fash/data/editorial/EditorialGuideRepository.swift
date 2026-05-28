import Foundation

/// Public common-service editorial guides — Android `EditorialGuideRepository`.
final class EditorialGuideRepository {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private func localeSegment() -> String {
        let tag = AppLocale.currentTag.trimmingCharacters(in: .whitespaces).lowercased()
        return tag.hasPrefix(AppLocale.tagEN) ? AppLocale.tagEN : AppLocale.tagVI
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
            throw CoreServiceHttpException(
                statusCode: http.statusCode,
                message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
            )
        }
        return data
    }

    func listAll(limit: Int = 50, offset: Int = 0) async -> Result<EditorialGuideListPage, Error> {
        let locale = localeSegment()
        let lim = min(max(limit, 1), 50)
        let off = max(offset, 0)
        var components = URLComponents(string: AppEnvironment.commonServicePath("api/v1/public/editorial-guides"))
        components?.queryItems = [
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "limit", value: "\(lim)"),
            URLQueryItem(name: "offset", value: "\(off)"),
        ]
        guard let urlString = components?.url?.absoluteString else {
            return .failure(URLError(.badURL))
        }
        do {
            let data = try await executeGet(urlString)
            return .success(parseCarouselPage(data))
        } catch {
            return .failure(error)
        }
    }

    func getBySlug(_ slug: String) async -> Result<EditorialGuideDetail, Error> {
        let trimmed = slug.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .failure(URLError(.badURL)) }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmed
        let locale = localeSegment()
        var components = URLComponents(
            string: AppEnvironment.commonServicePath("api/v1/public/editorial-guides/\(encoded)")
        )
        components?.queryItems = [URLQueryItem(name: "locale", value: locale)]
        guard let urlString = components?.url?.absoluteString else {
            return .failure(URLError(.badURL))
        }
        do {
            let data = try await executeGet(urlString)
            let root = try RepositoryHttp.jsonObject(data)
            guard let guide = root["guide"] as? [String: Any] else {
                return .failure(URLError(.cannotParseResponse))
            }
            return .success(parseDetail(guide))
        } catch {
            return .failure(error)
        }
    }

    private func parseCarouselPage(_ data: Data) -> EditorialGuideListPage {
        guard let root = try? RepositoryHttp.jsonObject(data),
              let itemsArr = root["items"] as? [[String: Any]] else {
            return EditorialGuideListPage(items: [], hasMore: false)
        }
        let items = itemsArr.map(parseStub)
        let hasMore = RepositoryHttp.optBool(root, "has_more", default: false)
        return EditorialGuideListPage(items: items, hasMore: hasMore)
    }

    private func parseStub(_ o: [String: Any]) -> HomeEditorialPostStub {
        let coverRaw = RepositoryHttp.optString(o, "cover_image_url").trimmingCharacters(in: .whitespaces)
        let cover = coverRaw.isEmpty ? EditorialGuideDefaults.defaultCoverURL : coverRaw
        let exploreCat = RepositoryHttp.optString(o, "explore_category_id").trimmingCharacters(in: .whitespaces)
        let exploreQ = RepositoryHttp.optString(o, "explore_search_query").trimmingCharacters(in: .whitespaces)
        return HomeEditorialPostStub(
            id: RepositoryHttp.optString(o, "id"),
            slug: RepositoryHttp.optString(o, "slug"),
            title: RepositoryHttp.optString(o, "title"),
            summary: RepositoryHttp.optString(o, "summary"),
            coverImageUrl: cover,
            exploreCategoryId: exploreCat.isEmpty ? nil : exploreCat,
            exploreSearchQuery: exploreQ.isEmpty ? nil : exploreQ
        )
    }

    private func parseDetail(_ o: [String: Any]) -> EditorialGuideDetail {
        let coverRaw = RepositoryHttp.optString(o, "cover_image_url").trimmingCharacters(in: .whitespaces)
        let cover = coverRaw.isEmpty ? EditorialGuideDefaults.defaultCoverURL : coverRaw
        let exploreCat = RepositoryHttp.optString(o, "explore_category_id").trimmingCharacters(in: .whitespaces)
        let exploreQ = RepositoryHttp.optString(o, "explore_search_query").trimmingCharacters(in: .whitespaces)
        return EditorialGuideDetail(
            id: RepositoryHttp.optString(o, "id"),
            slug: RepositoryHttp.optString(o, "slug"),
            title: RepositoryHttp.optString(o, "title"),
            summary: RepositoryHttp.optString(o, "summary"),
            bodyMarkdown: RepositoryHttp.optString(o, "body_markdown"),
            coverImageUrl: cover,
            exploreCategoryId: exploreCat.isEmpty ? nil : exploreCat,
            exploreSearchQuery: exploreQ.isEmpty ? nil : exploreQ
        )
    }
}
