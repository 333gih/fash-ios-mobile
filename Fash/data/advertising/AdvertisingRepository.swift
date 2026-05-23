import Foundation

final class AdvertisingRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
