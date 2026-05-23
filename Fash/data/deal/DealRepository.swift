import Foundation

final class DealRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
