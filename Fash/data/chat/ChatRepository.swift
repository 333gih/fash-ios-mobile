import Foundation

final class ChatRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }
}
