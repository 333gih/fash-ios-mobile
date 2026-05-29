import Foundation

/// Shared GET helpers for repository layers — mirrors Android OkHttp executeGet patterns.
enum RepositoryHttp {
    static func executeGet(
        urlString: String,
        client: SecuredApiClient,
        publicBrowse: Bool = false
    ) async throws -> Data {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, http): (Data, HTTPURLResponse)
        if publicBrowse {
            (data, http) = try await PublicBrowseHttp.data(for: req)
        } else {
            (data, http) = try await client.data(for: req)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CoreServiceHttpException(
                statusCode: http.statusCode,
                message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
            )
        }
        return data
    }

    /// Tries locale-prefixed URL then fallback without prefix (Android `coreApiCandidateUrls`).
    static func executeCoreGet(
        relativePath: String,
        client: SecuredApiClient,
        publicBrowse: Bool = false
    ) async throws -> Data {
        let path = relativePath.hasPrefix("api/") ? relativePath : "api/v1/\(relativePath)"
        if publicBrowse {
            let stripped = path
                .replacingOccurrences(of: "api/v1/public/", with: "")
                .replacingOccurrences(of: "api/v1/", with: "")
            return try await executeGet(
                urlString: PublicBrowseHttp.publicApiPath(stripped),
                client: client,
                publicBrowse: true
            )
        }
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in AppEnvironment.coreApiCandidateURLs(path) {
            do {
                return try await executeGet(urlString: urlString, client: client)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    static func parseStringArray(_ data: Data) -> [String] {
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return [] }
        if let arr = root as? [Any] {
            return arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        if let obj = root as? [String: Any], let arr = obj["data"] as? [Any] {
            return arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        return []
    }

    static func jsonObject(_ data: Data) throws -> [String: Any] {
        let root = try JSONSerialization.jsonObject(with: data)
        if let obj = root as? [String: Any] { return obj }
        throw URLError(.cannotParseResponse)
    }

    static func jsonArray(_ data: Data) -> [[String: Any]] {
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return [] }
        if let arr = root as? [[String: Any]] { return arr }
        if let obj = root as? [String: Any], let arr = obj["data"] as? [[String: Any]] { return arr }
        if let obj = root as? [String: Any], let arr = obj["items"] as? [[String: Any]] { return arr }
        return []
    }

    static func optString(_ obj: [String: Any], _ keys: String...) -> String {
        for key in keys {
            if let v = obj[key] as? String, !v.isEmpty { return v }
        }
        return ""
    }

    static func optLong(_ obj: [String: Any], _ keys: String...) -> Int64 {
        for key in keys {
            if let n = obj[key] as? NSNumber { return n.int64Value }
            if let s = obj[key] as? String, let v = Int64(s) { return v }
        }
        return 0
    }

    static func optBool(_ obj: [String: Any], _ keys: String..., default defaultValue: Bool = false) -> Bool {
        for key in keys {
            if let b = obj[key] as? Bool { return b }
            if let n = obj[key] as? NSNumber { return n.boolValue }
        }
        return defaultValue
    }

    static func optInt(_ obj: [String: Any], _ keys: String..., default defaultValue: Int = 0) -> Int {
        for key in keys {
            if let n = obj[key] as? NSNumber { return n.intValue }
        }
        return defaultValue
    }

    static func executePost(
        urlString: String,
        client: SecuredApiClient,
        body: Data,
        publicBrowse: Bool = false
    ) async throws {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (_, http): (Data, HTTPURLResponse)
        if publicBrowse {
            (_, http) = try await PublicBrowseHttp.data(for: req)
        } else {
            (_, http) = try await client.data(for: req)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    static func executeCoreDelete(
        relativePath: String,
        client: SecuredApiClient
    ) async throws {
        let path = relativePath.hasPrefix("api/") ? relativePath : "api/v1/\(relativePath)"
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in AppEnvironment.coreApiCandidateURLs(path) {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "DELETE"
            do {
                let (_, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else {
                    throw CoreServiceHttpException(
                        statusCode: http.statusCode,
                        message: "HTTP \(http.statusCode)"
                    )
                }
                return
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    static func executeCorePost(
        relativePath: String,
        client: SecuredApiClient,
        body: Data,
        publicBrowse: Bool = false
    ) async throws {
        let path = relativePath.hasPrefix("api/") ? relativePath : "api/v1/\(relativePath)"
        if publicBrowse {
            let stripped = path
                .replacingOccurrences(of: "api/v1/public/", with: "")
                .replacingOccurrences(of: "api/v1/", with: "")
            try await executePost(
                urlString: PublicBrowseHttp.publicApiPath(stripped),
                client: client,
                body: body,
                publicBrowse: true
            )
            return
        }
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in AppEnvironment.coreApiCandidateURLs(path) {
            do {
                try await executePost(urlString: urlString, client: client, body: body)
                return
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}
