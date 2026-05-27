import Foundation

/// Orders API — Android [OrderRepository] (list endpoints).
final class OrderRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) { self.client = client }

    func getBuyingOrders(limit: Int = 30, offset: Int = 0, status: String? = nil) async -> Result<[OrderItem], Error> {
        await getOrdersByRole("buyer", limit: limit, offset: offset, status: status)
    }

    func getSellingOrders(limit: Int = 30, offset: Int = 0, status: String? = nil) async -> Result<[OrderItem], Error> {
        await getOrdersByRole("seller", limit: limit, offset: offset, status: status)
    }

    private func getOrdersByRole(_ role: String, limit: Int, offset: Int, status: String?) async -> Result<[OrderItem], Error> {
        var query = "role=\(role)&limit=\(limit)&offset=\(offset)"
        if let s = status?.trimmingCharacters(in: .whitespaces), !s.isEmpty {
            let enc = s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
            query += "&status=\(enc)"
        }
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/orders?\(query)",
                client: client
            )
            return .success(parseOrders(data))
        } catch {
            let legacyPath = role == "buyer" ? "api/v1/orders/buying" : "api/v1/orders/selling"
            do {
                let data = try await RepositoryHttp.executeCoreGet(
                    relativePath: "\(legacyPath)?limit=\(limit)&offset=\(offset)",
                    client: client
                )
                return .success(parseOrders(data))
            } catch {
                return .failure(error)
            }
        }
    }

    private func parseOrders(_ data: Data) -> [OrderItem] {
        RepositoryHttp.jsonArray(data).map(mapOrderJson)
    }

    private func mapOrderJson(_ o: [String: Any]) -> OrderItem {
        let listing = o["listing"] as? [String: Any]
            ?? o["Listing"] as? [String: Any]
            ?? o["product"] as? [String: Any]
            ?? o
        let seller = o["seller"] as? [String: Any]
            ?? o["Seller"] as? [String: Any]
            ?? o["buyer"] as? [String: Any]
            ?? o
        let rawStatus = RepositoryHttp.optString(o, "status", "Status").lowercased()
        let coverUrl = RepositoryHttp.optString(listing, "cover_image_url", "CoverImageURL", "thumbnail_url")
        let imageUrls = listing["image_urls"] as? [String] ?? listing["ImageURLs"] as? [String]
        let imageUrl = coverUrl.isEmpty ? (imageUrls?.first ?? "") : coverUrl
        let canConfirm = RepositoryHttp.optBool(o, "can_confirm", "CanConfirm", default: rawStatus == "in_transit")
        let canReview = RepositoryHttp.optBool(o, "can_review", "CanReview", default: rawStatus == "delivered_confirmed")
        return OrderItem(
            orderId: RepositoryHttp.optString(o, "id", "ID", "order_id"),
            listingId: {
                let direct = RepositoryHttp.optString(o, "listing_id", "ListingID")
                return direct.isEmpty ? RepositoryHttp.optString(listing, "id", "ID") : direct
            }(),
            title: RepositoryHttp.optString(listing, "title", "Title", o["title"] as? String ?? ""),
            imageUrl: imageUrl,
            sellerUsername: RepositoryHttp.optString(seller, "username", "Username", o["seller_username"] as? String ?? ""),
            priceVnd: RepositoryHttp.optLong(o, "amount_vnd", "AmountVND") != 0
                ? RepositoryHttp.optLong(o, "amount_vnd", "AmountVND")
                : RepositoryHttp.optLong(listing, "price", "Price"),
            status: rawStatus.isEmpty ? "payment_pending" : rawStatus,
            canConfirm: canConfirm,
            canReview: canReview,
            createdAt: RepositoryHttp.optString(o, "created_at", "CreatedAt", "createdAt")
        )
    }
}

extension OrderRepository {
    func createOrder(listingId: String, amountVnd: Int64, shippingFeeVnd: Int64 = 0) async -> Result<String, Error> {
        let body: [String: Any] = [
            "listing_id": listingId.trimmingCharacters(in: .whitespacesAndNewlines),
            "amount_vnd": amountVnd,
            "shipping_fee_vnd": max(0, shippingFeeVnd),
        ]
        do {
            let data = try await postJSON(relativePath: "api/v1/orders", body: body)
            let root = try RepositoryHttp.jsonObject(data)
            let payload = (root["data"] as? [String: Any]) ?? root
            let orderId = RepositoryHttp.optString(payload, "id", "ID", "order_id")
                .ifEmpty(RepositoryHttp.optString(root, "id", "ID", "order_id"))
            guard !orderId.isEmpty else { return .failure(URLError(.cannotParseResponse)) }
            return .success(orderId)
        } catch {
            return .failure(error)
        }
    }

    private func postJSON(relativePath: String, body: [String: Any]) async throws -> Data {
        let urls = AppEnvironment.coreApiCandidateURLs(relativePath)
        var lastError: Error = URLError(.cannotConnectToHost)
        let payload = try JSONSerialization.data(withJSONObject: body)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = payload
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else {
                    throw CoreServiceHttpException(
                        statusCode: http.statusCode,
                        message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                    )
                }
                return data
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
