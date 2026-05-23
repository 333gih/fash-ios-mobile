import Foundation

final class CorePaymentRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
