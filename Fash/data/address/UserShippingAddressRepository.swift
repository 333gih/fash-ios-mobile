import Foundation

final class UserShippingAddressRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
