import Foundation

extension OrderRepository {
    /// `POST /orders/{id}/fulfillment` — buyer picks meetup vs online from `fulfillment_pending`.
    func chooseOrderFulfillment(orderId: String, fulfillment: String) async -> Result<Void, Error> {
        let oid = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        let channel = fulfillment.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !oid.isEmpty, !channel.isEmpty else { return .failure(URLError(.badURL)) }
        guard let body = try? JSONSerialization.data(withJSONObject: ["fulfillment": channel]) else {
            return .failure(URLError(.cannotParseResponse))
        }
        do {
            _ = try await RepositoryHttp.executeCorePost(
                relativePath: "api/v1/orders/\(oid)/fulfillment",
                client: client,
                body: body
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
