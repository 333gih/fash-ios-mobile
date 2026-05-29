import Foundation

extension OrderRepository {
    func confirmHandoff(orderId: String) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        return await postEmpty(relativePath: "api/v1/orders/\(id)/confirm-handoff")
    }

    func acknowledgeOfflineCash(orderId: String) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        return await postEmpty(relativePath: "api/v1/orders/\(id)/acknowledge-offline-cash")
    }

    func reportMeetingNoShow(
        orderId: String,
        reason: String,
        note: String = ""
    ) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !r.isEmpty else { return .failure(URLError(.badURL)) }
        var body: [String: Any] = ["reason": r]
        let n = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !n.isEmpty { body["note"] = n }
        return await postJSONVoid(relativePath: "api/v1/orders/\(id)/report-meeting-no-show", body: body)
    }

    func listShipmentCarriers() async -> Result<[ShipmentCarrier], Error> {
        do {
            let data = try await getJSON(relativePath: "api/v1/shipment/carriers")
            let top = (try? RepositoryHttp.jsonObject(data)) ?? [:]
            let root = (top["data"] as? [String: Any]) ?? top
            let arr = (root["carriers"] as? [[String: Any]]) ?? []
            let carriers = arr.compactMap { c -> ShipmentCarrier? in
                let id = RepositoryHttp.optString(c, "id", "ID")
                guard !id.isEmpty else { return nil }
                return ShipmentCarrier(
                    id: id,
                    name: {
                        let n = RepositoryHttp.optString(c, "name", "Name")
                        return n.isEmpty ? id : n
                    }(),
                    description: RepositoryHttp.optString(c, "description", "Description")
                )
            }
            return .success(carriers)
        } catch {
            return .failure(error)
        }
    }

    func bookShipment(orderId: String, carrierId: String) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cid = carrierId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !id.isEmpty, !cid.isEmpty else { return .failure(URLError(.badURL)) }
        return await postJSONVoid(
            relativePath: "api/v1/orders/\(id)/shipment/book",
            body: ["carrier_id": cid]
        )
    }

    func advanceMockShipment(orderId: String) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        return await postEmpty(relativePath: "api/v1/dev/shipment/\(id)/advance")
    }

    func shipOrder(orderId: String, trackingNumber: String, carrier: String) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        let tracking = trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !tracking.isEmpty else { return .failure(URLError(.badURL)) }
        let c = carrier.trimmingCharacters(in: .whitespacesAndNewlines)
        return await postJSONVoid(
            relativePath: "api/v1/orders/ship",
            body: [
                "order_id": id,
                "tracking_number": tracking,
                "carrier": c.isEmpty ? "—" : c,
            ]
        )
    }

    func submitReview(
        orderId: String,
        rating: Int,
        comment: String?,
        badgeIds: [ReviewBadgeRefPayload] = []
    ) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        var body: [String: Any] = ["order_id": id, "rating": rating]
        if let comment, !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body["comment"] = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if !badgeIds.isEmpty {
            body["badge_ids"] = badgeIds.map { b in
                var o: [String: Any] = ["id": b.badgeId]
                if !b.slug.isEmpty { o["slug"] = b.slug }
                return o
            }
        }
        return await postJSONVoid(relativePath: "api/v1/orders/review", body: body)
    }

    func openDispute(orderId: String, description: String, photoUrls: [String] = []) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = String(description.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !id.isEmpty, !desc.isEmpty else { return .failure(URLError(.badURL)) }
        let urls = photoUrls.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.prefix(10)
        return await postJSONVoid(
            relativePath: "api/v1/orders/dispute",
            body: ["order_id": id, "description": desc, "photo_urls": Array(urls)]
        )
    }

    func submitDisputeEvidence(
        orderId: String,
        description: String,
        photoUrls: [String] = []
    ) async -> Result<Void, Error> {
        let id = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = String(description.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !id.isEmpty, !desc.isEmpty else { return .failure(URLError(.badURL)) }
        let urls = photoUrls.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.prefix(10)
        return await postJSONVoid(
            relativePath: "api/v1/orders/dispute/evidence",
            body: ["order_id": id, "description": desc, "photo_urls": Array(urls)]
        )
    }

    private func getJSON(relativePath: String) async throws -> Data {
        let urls = AppEnvironment.coreApiCandidateURLs(relativePath)
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
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
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
