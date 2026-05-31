import Foundation

/// Core-service GET/PUT `/api/v1/users/me/notification-preferences`.
final class NotificationPreferencesRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) {
        self.client = client
    }

    private var baseURL: String {
        AppEnvironment.apiPath("api/v1/users/me/notification-preferences")
    }

    func getNotificationPreferences() async -> Result<NotificationPreferences, Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/users/me/notification-preferences",
                client: client
            )
            let obj = try RepositoryHttp.jsonObject(data)
            return .success(NotificationPreferencesParsing.parse(obj))
        } catch {
            return .failure(error)
        }
    }

    func updateNotificationPreferences(_ prefs: NotificationPreferences) async -> Result<NotificationPreferences, Error> {
        guard let url = URL(string: baseURL) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: NotificationPreferencesParsing.toPutJSON(prefs))
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(
                    statusCode: http.statusCode,
                    message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                )
            }
            let obj = try RepositoryHttp.jsonObject(data)
            return .success(NotificationPreferencesParsing.parse(obj))
        } catch {
            return .failure(error)
        }
    }
}
