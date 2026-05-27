import Foundation

final class CorePaymentRepository {
    private let client: SecuredApiClient
    init(client: SecuredApiClient) { self.client = client }

    func listPaymentMethods() async -> Result<[PaymentGatewayOption], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(relativePath: "api/v1/payment-methods", client: client)
            return .success(parsePaymentMethods(data))
        } catch {
            return .failure(error)
        }
    }

    func initiatePayment(
        orderId: String,
        paymentMethod: String,
        redirectUrl: String,
        shipping: CheckoutAddressPayload?
    ) async -> Result<PaymentInitiateResult, Error> {
        let oid = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !oid.isEmpty else { return .failure(URLError(.badURL)) }
        let path = String(format: BuildConfig.corePaymentInitiatePath, oid)
        var body: [String: Any] = [
            "payment_method": paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            "redirect_url": redirectUrl.trimmingCharacters(in: .whitespacesAndNewlines),
        ]
        if let shipping {
            body["shipping_address"] = [
                "recipient_name": shipping.fullName,
                "phone": shipping.phone,
                "line1": shipping.address,
                "district": shipping.district,
                "city": shipping.city,
            ]
        }
        do {
            let data = try await postJSON(relativePath: path, body: body)
            return .success(try parseInitiateResponse(data))
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
            req.setValue(UUID().uuidString, forHTTPHeaderField: "X-Idempotency-Key")
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

    private func parsePaymentMethods(_ data: Data) -> [PaymentGatewayOption] {
        guard let root = try? RepositoryHttp.jsonObject(data) else { return [] }
        let payload = (root["data"] as? [String: Any]) ?? root
        let arr = (payload["payment_methods"] as? [[String: Any]]) ?? []
        return arr.compactMap { row in
            guard RepositoryHttp.optBool(row, "enabled", default: true) else { return nil }
            let id = RepositoryHttp.optString(row, "id", "ID").lowercased()
            guard !id.isEmpty else { return nil }
            let name = RepositoryHttp.optString(row, "name", "Name").ifEmpty(id)
            return PaymentGatewayOption(id: id, name: name)
        }
    }

    private func parseInitiateResponse(_ data: Data) throws -> PaymentInitiateResult {
        let root = try RepositoryHttp.jsonObject(data)
        let payload = (root["data"] as? [String: Any]) ?? root
        let paymentUrl = RepositoryHttp.optString(payload, "payment_url", "paymentUrl", "PaymentURL", "checkout_url")
        guard !paymentUrl.isEmpty else { throw URLError(.cannotParseResponse) }
        let tx = RepositoryHttp.optString(payload, "transaction_id", "transactionId")
        return PaymentInitiateResult(paymentUrl: paymentUrl, transactionId: tx.isEmpty ? nil : tx)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
