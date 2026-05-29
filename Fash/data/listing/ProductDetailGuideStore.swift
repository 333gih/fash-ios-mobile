import Foundation

final class ProductDetailGuideStore {
    private let defaults: UserDefaults
    private let prefix = "fash.pdp.purchase_guide_seen."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasSeenPurchaseGuide(userId: String) -> Bool {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return true }
        return defaults.bool(forKey: prefix + uid)
    }

    func markPurchaseGuideSeen(userId: String) {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }
        defaults.set(true, forKey: prefix + uid)
    }
}
