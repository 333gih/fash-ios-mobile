import Foundation

extension ListingRepository {
    func getListingDetailFull(listingId: String, publicBrowse: Bool = false) async -> Result<ListingDetail, Error> {
        let urlString: String
        if publicBrowse {
            urlString = PublicBrowseHttp.publicApiPath("listings/\(listingId)")
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
                data = d
                http = h
            } else {
                (data, http) = try await client.data(for: req)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(
                    statusCode: http.statusCode,
                    message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                )
            }
            if let detail = try ListingFeedJsonParser.parseFullListingDetail(data) {
                return .success(detail)
            }
            return .failure(URLError(.cannotParseResponse))
        } catch {
            return .failure(error)
        }
    }
}
