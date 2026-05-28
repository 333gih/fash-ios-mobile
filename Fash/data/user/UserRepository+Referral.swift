import Foundation

extension UserRepository {
    /// `GET /api/v1/users/me/referral-invite-token` — Android `getReferralInviteTokenOrNull`.
    func getReferralInviteTokenOrNull() async -> String? {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/users/me/referral-invite-token",
                client: client
            )
            let root = try RepositoryHttp.jsonObject(data)
            let obj = (root["data"] as? [String: Any]) ?? root
            guard RepositoryHttp.optBool(obj, "enabled", default: false) else { return nil }
            let token = RepositoryHttp.optString(obj, "referral_token").trimmingCharacters(in: .whitespaces)
            return token.isEmpty ? nil : token
        } catch {
            return nil
        }
    }
}
