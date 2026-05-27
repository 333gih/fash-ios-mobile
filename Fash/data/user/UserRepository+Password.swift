import Foundation

extension UserRepository {
    /// Auth-service `POST .../auth/change-password` — Android `putUserPassword`.
    func putUserPassword(newPassword: String, currentPassword: String?) async -> Result<Void, Error> {
        guard (8...72).contains(newPassword.count) else {
            return .failure(NSError(domain: "FashPassword", code: 0, userInfo: [NSLocalizedDescriptionKey: "PASSWORD_LENGTH"]))
        }
        let path = AppEnvironment.authChangePasswordPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: AppEnvironment.authServicePath(path)) else {
            return .failure(URLError(.badURL))
        }
        var payload: [String: Any] = ["new_password": newPassword]
        let cur = currentPassword?.trimmingCharacters(in: .whitespaces) ?? ""
        if !cur.isEmpty { payload["current_password"] = cur }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
                let code = RepositoryHttp.optString(obj, "code", "error_code")
                let err = RepositoryHttp.optString(obj, "error", "message")
                let combined = "\(code) \(err)"
                if combined.localizedCaseInsensitiveContains("INVALID_CURRENT_PASSWORD") {
                    return .failure(NSError(domain: "FashPassword", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "INVALID_CURRENT_PASSWORD"]))
                }
                if combined.localizedCaseInsensitiveContains("CURRENT_PASSWORD_REQUIRED") {
                    return .failure(NSError(domain: "FashPassword", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "CURRENT_PASSWORD_REQUIRED"]))
                }
                return .failure(CoreServiceHttpException(statusCode: http.statusCode, message: err.isEmpty ? combined : err))
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func searchUsers(query: String, limit: Int = 20, publicBrowse: Bool = false) async -> Result<[UserSearchResult], Error> {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return .success([]) }
        let enc = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        let capped = min(max(limit, 1), 50)
        do {
            let data: Data
            if publicBrowse {
                data = try await RepositoryHttp.executeGet(
                    urlString: PublicBrowseHttp.publicApiPath("browse/sellers") + "?q=\(enc)&limit=\(capped)",
                    client: client,
                    publicBrowse: true
                )
            } else {
                data = try await RepositoryHttp.executeCoreGet(
                    relativePath: "api/v1/users/search?q=\(enc)&limit=\(capped)",
                    client: client
                )
            }
            let rows = RepositoryHttp.jsonArray(data)
            let items = rows.map { o -> UserSearchResult in
                UserSearchResult(
                    userId: RepositoryHttp.optString(o, "user_id", "UserID", "id", "ID"),
                    username: RepositoryHttp.optString(o, "username", "Username"),
                    displayName: RepositoryHttp.optString(o, "display_name", "DisplayName", "name", "Name"),
                    avatarUrl: RepositoryHttp.optString(o, "avatar_url", "AvatarURL"),
                    followerCount: RepositoryHttp.optInt(o, "follower_count", "FollowerCount"),
                    verified: RepositoryHttp.optBool(o, "verified", "Verified"),
                    followingCount: RepositoryHttp.optInt(o, "following_count", "FollowingCount"),
                    listingCount: RepositoryHttp.optInt(o, "listing_count", "ListingCount", "product_count", "ProductCount")
                )
            }
            return .success(items)
        } catch {
            return .failure(error)
        }
    }
}
