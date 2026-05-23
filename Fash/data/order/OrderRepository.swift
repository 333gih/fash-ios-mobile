import Foundation

final class OrderRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
