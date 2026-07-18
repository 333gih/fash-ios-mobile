import Foundation

/// Session-scoped A/B assignment from recommendation API meta/headers (`experiment_key:variant`).
final class RecExperimentContext: @unchecked Sendable {
    static let shared = RecExperimentContext()

    private let lock = NSLock()
    private var experimentId: String?
    private var configVersionId: String?

    private init() {}

    func update(configVersionId: String?, activeExperiments: [[String: Any]]?) {
        lock.lock()
        defer { lock.unlock() }
        self.configVersionId = configVersionId?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.experimentId = Self.experimentId(from: activeExperiments)
    }

    func update(experimentIdHeader: String?) {
        let trimmed = experimentIdHeader?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        guard let trimmed else { return }
        lock.lock()
        experimentId = trimmed
        lock.unlock()
    }

    func experimentIdForFeedEvents() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return experimentId
    }

    func clear() {
        lock.lock()
        experimentId = nil
        configVersionId = nil
        lock.unlock()
    }

    static func isRecommendationSurface(_ surface: String) -> Bool {
        let s = surface.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s.isEmpty { return false }
        if s == FeedSurfaces.appOpen || s == FeedSurfaces.notificationOpen { return false }
        let recSurfaces: Set<String> = [
            "for_you", "recommendation_for_you", "style_picks", "recommendation_style",
            "similar_to_saved", "seasonal_near_you", "hunt_today", "explore", "home",
            "recommendation_continue", "recommendation_daily_digest", "continue_browsing",
        ]
        return recSurfaces.contains(s) || s.hasPrefix("recommendation_")
    }

    static func parseMeta(from payload: [String: Any]) {
        guard let meta = payload["recommendation_meta"] as? [String: Any] else { return }
        let versionId = meta["config_version_id"] as? String
        let experiments = meta["active_experiments"] as? [[String: Any]]
        shared.update(configVersionId: versionId, activeExperiments: experiments)
    }

    static func applyResponseHeaders(_ headers: [AnyHashable: Any]) {
        if let id = headerValue(headers, names: ["X-Rec-Experiment-Id", "x-rec-experiment-id"]) {
            shared.update(experimentIdHeader: id)
        }
    }

    private static func experimentId(from experiments: [[String: Any]]?) -> String? {
        guard let experiments, let first = experiments.first else { return nil }
        let key = (first["experiment_key"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let variant = (first["variant"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if key.isEmpty { return nil }
        return variant.isEmpty ? key : "\(key):\(variant)"
    }

    private static func headerValue(_ headers: [AnyHashable: Any], names: [String]) -> String? {
        for (key, value) in headers {
            guard let keyStr = (key as? String)?.lowercased() else { continue }
            if names.contains(where: { $0.lowercased() == keyStr }) {
                if let s = value as? String { return s.nilIfEmpty }
            }
        }
        return nil
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
