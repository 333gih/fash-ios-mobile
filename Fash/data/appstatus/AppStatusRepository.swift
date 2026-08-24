import Foundation

struct AppMaintenanceStatus: Equatable {
    var maintenance: Bool
    var title: String?
    var message: String?

    static let open = AppMaintenanceStatus(maintenance: false, title: nil, message: nil)
}

/// Public kill-switch: `GET /api/v1/app/status` (no attestation).
final class AppStatusRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) {
        self.client = client
    }

    func fetch() async throws -> AppMaintenanceStatus {
        let data = try await RepositoryHttp.executeCoreGet(
            relativePath: "api/v1/app/status",
            client: client
        )
        let root = try RepositoryHttp.jsonObject(data)
        let payload = (root["data"] as? [String: Any]) ?? root
        let maintenance = boolValue(payload["maintenance"]) || boolValue(payload["enabled"])
        let title = stringValue(payload["title"])
        let message = stringValue(payload["message"])
        return AppMaintenanceStatus(
            maintenance: maintenance,
            title: title,
            message: message
        )
    }

    private func boolValue(_ raw: Any?) -> Bool {
        if let b = raw as? Bool { return b }
        if let n = raw as? NSNumber { return n.boolValue }
        if let s = raw as? String {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return t == "true" || t == "1" || t == "yes"
        }
        return false
    }

    private func stringValue(_ raw: Any?) -> String? {
        guard let s = raw as? String else { return nil }
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
