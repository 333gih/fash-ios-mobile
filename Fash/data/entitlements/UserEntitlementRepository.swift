import Foundation

final class UserEntitlementRepository {
    private let client: SecuredApiClient
    private var cached: UserEntitlementSummary?

    init(client: SecuredApiClient) {
        self.client = client
    }

    func peekCached() -> UserEntitlementSummary? { cached }

    func clearCache() { cached = nil }

    func fetchEntitlements() async -> Result<UserEntitlementSummary, Error> {
        do {
            let url = AppEnvironment.apiPath("api/v1/users/me/entitlements")
            let data = try await RepositoryHttp.executeGet(urlString: url, client: client)
            let summary = try parseSummary(data)
            cached = summary
            return .success(summary)
        } catch {
            return .failure(error)
        }
    }

    func mockPurchasePackage(packageId: String) async -> Result<PackageActivationResult, Error> {
        let id = packageId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let url = AppEnvironment.apiPath("api/v1/app/advertising/product-packages/\(id)/mock-purchase")
            var req = URLRequest(url: URL(string: url)!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = Data("{}".utf8)
            let (data, resp) = try await client.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return .failure(URLError(.badServerResponse))
            }
            let result = try parseActivation(data)
            if let ent = result.entitlements { cached = ent }
            else if case .success(let fresh) = await fetchEntitlements() {
                return .success(PackageActivationResult(
                    packageCode: fresh.packageCode,
                    packageName: fresh.packageName,
                    entitlements: fresh
                ))
            }
            return .success(result)
        } catch {
            return .failure(error)
        }
    }

    func applyExploreBoost(listingId: String) async -> Result<Void, Error> {
        let id = listingId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let url = AppEnvironment.apiPath("api/v1/listings/\(id)/explore-boost")
            try await RepositoryHttp.executePost(urlString: url, client: client, body: Data("{}".utf8))
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func requestAuthenticity(listingId: String) async -> Result<Void, Error> {
        await postSeller(path: "api/v1/seller/authenticity-requests", body: ["listing_id": listingId])
    }

    func requestFanpage(listingId: String, caption: String) async -> Result<Void, Error> {
        await postSeller(path: "api/v1/seller/fanpage-requests", body: ["listing_id": listingId, "caption": caption])
    }

    func requestSocialPromo(listingId: String, caption: String) async -> Result<Void, Error> {
        await postSeller(path: "api/v1/seller/social-promo-requests", body: ["listing_id": listingId, "caption": caption])
    }

    private func postSeller(path: String, body: [String: String]) async -> Result<Void, Error> {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            let url = AppEnvironment.apiPath(path)
            try await RepositoryHttp.executePost(urlString: url, client: client, body: jsonData)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func parseSummary(_ data: Data) throws -> UserEntitlementSummary {
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let root = (obj["data"] as? [String: Any]) ?? obj
        var features: [String: FeatureUsageSummary] = [:]
        if let featObj = root["features"] as? [String: Any] {
            for (key, val) in featObj {
                guard let f = val as? [String: Any] else { continue }
                features[key] = FeatureUsageSummary(
                    enabled: f["enabled"] as? Bool ?? false,
                    used: (f["used"] as? NSNumber)?.int64Value ?? 0,
                    remaining: (f["remaining"] as? NSNumber)?.int64Value,
                    unlimited: f["unlimited"] as? Bool ?? false,
                    durationDays: f["duration_days"] as? Int ?? 0,
                    priority: f["priority"] as? Bool ?? false
                )
            }
        }
        return UserEntitlementSummary(
            packageId: root["package_id"] as? String ?? "",
            packageCode: root["package_code"] as? String ?? "",
            packageName: root["package_name"] as? String ?? "",
            features: features
        )
    }

    private func parseActivation(_ data: Data) throws -> PackageActivationResult {
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let root = (obj["data"] as? [String: Any]) ?? obj
        var ent: UserEntitlementSummary?
        if let entObj = root["entitlements"] as? [String: Any],
           let entData = try? JSONSerialization.data(withJSONObject: entObj) {
            ent = try? parseSummary(entData)
        }
        return PackageActivationResult(
            packageCode: root["package_code"] as? String ?? ent?.packageCode ?? "",
            packageName: root["package_name"] as? String ?? ent?.packageName ?? "",
            entitlements: ent
        )
    }
}
