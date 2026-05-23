import Foundation

final class ListingRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) {
        self.client = client
    }

    func getHomeFeed(limit: Int = 20, offset: Int = 0) async -> Result<[ListingFeedItem], Error> {
        let path = "api/v1/listings/home?limit=\(limit)&offset=\(offset)"
        let urls = AppEnvironment.coreApiCandidateURLs(path)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else { continue }
                return .success(try ListingFeedJsonParser.parseFeed(data))
            } catch {
                continue
            }
        }
        return .failure(URLError(.cannotConnectToHost))
    }

    func getListingDetail(listingId: String, publicBrowse: Bool = false) async -> Result<ListingFeedItem, Error> {
        let urlString: String
        if publicBrowse {
            urlString = PublicBrowseHttp.publicApiPath("api/v1/public/listings/\(listingId)")
        } else {
            urlString = AppEnvironment.apiPath("api/v1/listings/\(listingId)")
        }
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if publicBrowse {
            PublicBrowseHttp.applyGuestHeaders(&req)
        }
        do {
            let (data, http): (Data, HTTPURLResponse)
            if publicBrowse {
                let (d, r) = try await URLSession.shared.data(for: req)
                guard let h = r as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                data = d; http = h
            } else {
                (data, http) = try await client.data(for: req)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
            }
            let items = try ListingFeedJsonParser.parseFeed(data)
            if let first = items.first { return .success(first) }
            let obj = try HttpJson.dictionary(data)
            if let id = obj["id"] as? String {
                return .success(ListingFeedItem(
                    id: id,
                    title: obj["title"] as? String ?? "",
                    price: (obj["price"] as? NSNumber)?.int64Value ?? 0,
                    imageURL: nil,
                    sellerUsername: nil,
                ))
            }
            return .failure(URLError(.cannotParseResponse))
        } catch {
            return .failure(error)
        }
    }
}
