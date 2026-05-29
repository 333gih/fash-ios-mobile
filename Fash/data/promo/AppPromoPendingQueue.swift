import Foundation

/// In-memory queue when multiple promos arrive at once — Android `AppPromoPendingQueue`.
enum AppPromoPendingQueue {
    private static let lock = NSLock()
    private static var pending: [String: AppPromoCampaign] = [:]

    static func enqueue(_ campaign: AppPromoCampaign) {
        lock.lock()
        defer { lock.unlock() }
        if let existing = pending[campaign.campaignId] {
            if campaign.priority >= existing.priority {
                pending[campaign.campaignId] = campaign
            }
        } else {
            pending[campaign.campaignId] = campaign
        }
    }

    static func peekHighest() -> AppPromoCampaign? {
        lock.lock()
        defer { lock.unlock() }
        return pending.values.max(by: comparePriority)
    }

    static func pollHighest() -> AppPromoCampaign? {
        lock.lock()
        defer { lock.unlock() }
        guard let best = pending.values.max(by: comparePriority) else { return nil }
        pending.removeValue(forKey: best.campaignId)
        return best
    }

    static func clear() {
        lock.lock()
        pending.removeAll()
        lock.unlock()
    }

    private static func comparePriority(_ a: AppPromoCampaign, _ b: AppPromoCampaign) -> Bool {
        if a.priority != b.priority { return a.priority < b.priority }
        return a.campaignId > b.campaignId
    }
}
