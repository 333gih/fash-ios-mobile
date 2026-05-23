import Foundation
import Observation

@Observable
@MainActor
final class ExploreViewModel {
    var query = ""
    var items: [ListingFeedItem] = []
    var isLoading = false

    func refresh(deps: AppDependencies) async {
        isLoading = true
        defer { isLoading = false }
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            let result = await deps.listingRepository.getHomeFeed(limit: 40)
            if case .success(let feed) = result { items = feed }
            return
        }
        let path = "api/v1/search/listings?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&limit=40"
        let urlString = AppEnvironment.apiPath(path)
        guard let url = URL(string: urlString) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (data, http) = try await deps.securedClient.data(for: req)
            guard (200..<300).contains(http.statusCode) else { return }
            items = try ListingFeedJsonParser.parseFeed(data)
        } catch {
            items = []
        }
    }
}
