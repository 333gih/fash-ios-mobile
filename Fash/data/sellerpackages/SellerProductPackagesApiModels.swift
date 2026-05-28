import Foundation

enum SellerProductPackagesApiModels {
    static func parseResponse(_ data: Data) throws -> SellerProductPackagesResponse {
        let root = try RepositoryHttp.jsonObject(data)
        let arr = root["packages"] as? [[String: Any]] ?? []
        var packages: [SellerProductPackage] = []
        for o in arr {
            if let pkg = parsePackage(o) { packages.append(pkg) }
        }
        packages.sort { ($0.tier, $0.code) < ($1.tier, $1.code) }
        let serverNow = RepositoryHttp.optString(root, "server_now_utc").trimmingCharacters(in: .whitespaces)
        return SellerProductPackagesResponse(
            packages: packages,
            serverNowUtc: serverNow.isEmpty ? nil : serverNow
        )
    }

    static func parsePackage(_ o: [String: Any]) -> SellerProductPackage? {
        let code = RepositoryHttp.optString(o, "code").trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return nil }
        let tierRaw = RepositoryHttp.optString(o, "tier").trimmingCharacters(in: .whitespaces).lowercased()
        let tierKey = tierRaw.isEmpty ? "starter" : tierRaw
        let tier: PackageTier = switch tierKey {
        case "growth": .growth
        case "premium": .premium
        default: .starter
        }
        var features: [SellerPackageFeature] = []
        if let arr = o["features"] as? [[String: Any]] {
            for f in arr {
                let id = RepositoryHttp.optString(f, "id").trimmingCharacters(in: .whitespaces)
                guard !id.isEmpty else { continue }
                let highlight = RepositoryHttp.optString(f, "highlight").trimmingCharacters(in: .whitespaces)
                let apiName = RepositoryHttp.optString(f, "name").trimmingCharacters(in: .whitespaces)
                features.append(
                    SellerPackageFeature(
                        id: id,
                        included: SellerPackageJsonParsing.wireBoolean(f, keys: ["included", "Included"], default: false),
                        highlight: highlight.isEmpty ? nil : highlight,
                        name: apiName.isEmpty ? nil : apiName
                    )
                )
            }
        }
        let badge = RepositoryHttp.optString(o, "badge_label").trimmingCharacters(in: .whitespaces)
        return SellerProductPackage(
            id: RepositoryHttp.optString(o, "id"),
            code: code,
            name: RepositoryHttp.optString(o, "name"),
            description: RepositoryHttp.optString(o, "description"),
            priceVnd: RepositoryHttp.optLong(o, "price_vnd"),
            durationDays: max(1, RepositoryHttp.optInt(o, "duration_days", default: 30)),
            tier: tier,
            isReleased: SellerPackageJsonParsing.wireReleasedFlag(o),
            isBestSeller: SellerPackageJsonParsing.wireBoolean(o, keys: ["is_best_seller", "isBestSeller", "IsBestSeller"], default: false),
            badgeLabel: badge.isEmpty ? nil : badge,
            active: SellerPackageJsonParsing.wireBoolean(o, keys: ["active", "Active"], default: true),
            features: features
        )
    }
}
