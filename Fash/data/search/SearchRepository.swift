import Foundation

final class SearchRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
