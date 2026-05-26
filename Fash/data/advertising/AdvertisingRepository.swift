import Foundation

/// Core-service advertising CMS — mirrors Android [AdvertisingRepository].
final class AdvertisingRepository {
    private let securedClient: SecuredApiClient

    init(client: SecuredApiClient) {
        self.securedClient = client
    }

    func getSlides(placement: String = "promo_slider_main", publicBrowse: Bool = false) async -> Result<AppAdvertisingSlidesResponse, Error> {
        let q = placement.trimmingCharacters(in: .whitespaces).isEmpty ? "promo_slider_main" : placement.trimmingCharacters(in: .whitespaces)
        if publicBrowse {
            return await getSlidesPublic(placement: q)
        }
        let relative = "api/v1/app/advertising/slides?placement=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)"
        let urls = AppEnvironment.coreApiCandidateURLs(relative)
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            applyLocaleHeaders(&req)
            do {
                let (data, http) = try await securedClient.data(for: req)
                guard (200..<300).contains(http.statusCode) else { continue }
                let raw = String(data: data, encoding: .utf8) ?? ""
                return .success(try AppAdvertisingSlidesParser.parse(raw))
            } catch {
                lastError = error
            }
        }
        if PublicBrowseHttp.isConfigured {
            return await getSlidesPublic(placement: q)
        }
        return .failure(lastError)
    }

    private func getSlidesPublic(placement: String) async -> Result<AppAdvertisingSlidesResponse, Error> {
        guard PublicBrowseHttp.isConfigured else {
            return .failure(URLError(.userAuthenticationRequired))
        }
        var components = URLComponents(string: PublicBrowseHttp.publicApiPath("app/advertising/slides"))
        components?.queryItems = [URLQueryItem(name: "placement", value: placement)]
        guard let url = components?.url else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (data, http) = try await PublicBrowseHttp.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                return .failure(URLError(.badServerResponse))
            }
            let raw = String(data: data, encoding: .utf8) ?? ""
            return .success(try AppAdvertisingSlidesParser.parse(raw))
        } catch {
            return .failure(error)
        }
    }

    private func applyLocaleHeaders(_ request: inout URLRequest) {
        let locale = AppLocale.coreApiPathSegment()
        request.setValue(locale, forHTTPHeaderField: "Accept-Language")
        request.setValue(locale, forHTTPHeaderField: "X-Fash-Lang")
    }
}
