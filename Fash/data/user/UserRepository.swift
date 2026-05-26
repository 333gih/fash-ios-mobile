import Foundation

struct SetupStatusGate: Decodable {
    var canAccessHome: Bool
    var nextStep: String?

    enum CodingKeys: String, CodingKey {
        case canAccessHome = "can_access_home"
        case nextStep = "next_step"
    }
}

final class UserRepository {
    let client: SecuredApiClient

    init(client: SecuredApiClient) {
        self.client = client
    }

    func fetchSetupStatus() async -> Result<SetupStatusGate, Error> {
        let urls = AppEnvironment.coreApiCandidateURLs(AppEnvironment.userAccessStatusPath)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else { continue }
                let gate = try JSONDecoder().decode(SetupStatusGate.self, from: data)
                return .success(gate)
            } catch {
                continue
            }
        }
        return .failure(URLError(.cannotConnectToHost))
    }

    /// `PUT /users/me/locale` — syncs push/in-app notification language (`en` or `vi`).
    func syncPreferredLocale(_ locale: String) async -> Result<Void, Error> {
        let tag = locale.lowercased().hasPrefix(AppLocale.tagEN) ? AppLocale.tagEN : AppLocale.tagVI
        let urls = AppEnvironment.coreApiCandidateURLs("api/v1/users/me/locale")
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                req.httpBody = try JSONSerialization.data(withJSONObject: ["locale": tag])
                let (_, http) = try await client.data(for: req)
                if (200..<300).contains(http.statusCode) {
                    return .success(())
                }
            } catch {
                continue
            }
        }
        return .failure(URLError(.cannotConnectToHost))
    }
}
