import Foundation

/// Pull backup for admin promo interstitials — Android `AppPromoInterstitialRepository`.
final class AppPromoInterstitialRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) { self.client = client }

    func fetchActiveCampaigns() async -> Result<[AppPromoCampaign], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/app/promo-interstitials/active",
                client: client
            )
            let obj = try RepositoryHttp.jsonObject(data)
            let rows = obj["campaigns"] as? [[String: Any]] ?? []
            let campaigns = rows.compactMap { row -> AppPromoCampaign? in
                guard let payload = RemoteAppPromoModels.parseRemoteAppPromoPayload(row) else { return nil }
                return RemoteAppPromoModels.toAppPromoCampaign(payload)
            }
            return .success(campaigns.sorted { $0.priority > $1.priority })
        } catch {
            return .failure(error)
        }
    }
}
