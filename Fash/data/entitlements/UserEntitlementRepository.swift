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

    func invokeFeature(featureKey: String, listingId: String, caption: String = "") async -> Result<Void, Error> {
        let key = featureKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return .failure(URLError(.badURL)) }
        return await postSeller(
            path: "api/v1/seller/package-features/\(key)/invoke",
            body: ["listing_id": listingId, "caption": caption]
        )
    }

    func applyExploreBoost(listingId: String) async -> Result<Void, Error> {
        await invokeFeature(featureKey: "explore_boost", listingId: listingId)
    }

    func requestAuthenticity(listingId: String) async -> Result<Void, Error> {
        await invokeFeature(featureKey: "authenticity_verify", listingId: listingId)
    }

    func requestFanpage(listingId: String, caption: String) async -> Result<Void, Error> {
        await invokeFeature(featureKey: "fanpage_spotlight", listingId: listingId, caption: caption)
    }

    func requestSocialPromo(listingId: String, caption: String) async -> Result<Void, Error> {
        await invokeFeature(featureKey: "social_tiktok_instagram", listingId: listingId, caption: caption)
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
                    featureGroup: f["feature_group"] as? String ?? "",
                    executionKind: f["execution_kind"] as? String ?? "",
                    name: f["name"] as? String ?? "",
                    description: f["description"] as? String ?? "",
                    requiresListing: f["requires_listing"] as? Bool ?? false,
                    fulfillmentMode: f["fulfillment_mode"] as? String ?? "",
                    verificationKind: f["verification_kind"] as? String ?? "",
                    disclaimerText: f["disclaimer_text"] as? String ?? "",
                    latestRequestStatus: f["latest_request_status"] as? String ?? "",
                    latestResultVerdict: f["latest_result_verdict"] as? String ?? "",
                    latestConfidencePct: f["latest_confidence_pct"] as? Int,
                    boostAffinityHint: f["boost_affinity_hint"] as? String ?? "",
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
