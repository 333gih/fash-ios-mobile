import Foundation

/// Reports `notification_open` feed events from push / in-app notification payloads.
enum NotificationEngagementReporter {
    static func reportOpen(reporter: FeedEventReporter, data: [String: String]?) {
        let listingId = firstString(data, keys: "listing_id", "listingId")
        let scenarioId = firstString(data, keys: "scenario_id", "scenarioId")
        reporter.notificationOpen(listingId: listingId, scenarioId: scenarioId)
    }

    private static func firstString(_ data: [String: String]?, keys: String...) -> String? {
        guard let data else { return nil }
        let byLower = Dictionary(uniqueKeysWithValues: data.map { ($0.key.lowercased(), $0.value) })
        for key in keys {
            let value = byLower[key.lowercased()]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty { return value }
        }
        return nil
    }
}
