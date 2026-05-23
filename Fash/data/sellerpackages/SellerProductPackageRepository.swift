import Foundation

final class SellerProductPackageRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
