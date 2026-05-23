import Foundation

extension UserRepository {
    func listMyNotificationGroups() async -> Result<InboxNotificationGroupsPage, Error> {
        await fetchInboxGroups(path: "api/v1/users/me/notifications/groups")
    }

    func listMyNotifications(limit: Int = 30, beforeId: String? = nil, group: String? = nil) async -> Result<InboxNotificationsPage, Error> {
        var path = "api/v1/users/me/notifications?limit=\(min(max(limit, 1), 100))"
        if let beforeId, !beforeId.isEmpty {
            path += "&before_id=\(beforeId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? beforeId)"
        }
        if let group, !group.isEmpty {
            path += "&group=\(group.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? group)"
        }
        return await fetchInboxPage(path: path)
    }

    func getMyNotificationsUnreadCount() async -> Result<Int, Error> {
        let urlString = AppEnvironment.apiPath("api/v1/users/me/notifications/unread-count")
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
            }
            let root = try HttpJson.dictionary(data)
            return .success(max(0, (root["unread_count"] as? NSNumber)?.intValue ?? 0))
        } catch {
            return .failure(error)
        }
    }

    func markNotificationRead(notificationId: String) async -> Result<Void, Error> {
        let encoded = notificationId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? notificationId
        let urlString = AppEnvironment.apiPath("api/v1/users/me/notifications/\(encoded)/read")
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)
        do {
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func markAllNotificationsRead(group: String? = nil) async -> Result<Int, Error> {
        var urlString = AppEnvironment.apiPath("api/v1/users/me/notifications/read-all")
        if let group, !group.isEmpty {
            urlString += (urlString.contains("?") ? "&" : "?") + "group=\(group.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? group)"
        }
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)
        do {
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
            }
            let root = try HttpJson.dictionary(data)
            let payload = (root["data"] as? [String: Any]) ?? root
            return .success(max(0, (payload["updated_count"] as? NSNumber)?.intValue ?? 0))
        } catch {
            return .failure(error)
        }
    }

    private func fetchInboxPage(path: String) async -> Result<InboxNotificationsPage, Error> {
        let urlString = AppEnvironment.apiPath(path)
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
            }
            return .success(try InboxNotificationParser.parsePage(data))
        } catch {
            return .failure(error)
        }
    }

    private func fetchInboxGroups(path: String) async -> Result<InboxNotificationGroupsPage, Error> {
        let urlString = AppEnvironment.apiPath(path)
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
            }
            return .success(try InboxNotificationParser.parseGroupsPage(data))
        } catch {
            return .failure(error)
        }
    }
}
