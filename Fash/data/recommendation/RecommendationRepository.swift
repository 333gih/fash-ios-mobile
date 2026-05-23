import Foundation

final class RecommendationRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
