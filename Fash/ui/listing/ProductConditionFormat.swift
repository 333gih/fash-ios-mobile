import Foundation

enum ProductConditionFormat {
    static func label(for raw: String?) -> String? {
        guard let raw else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return nil }
        switch key {
        case "new", "new_with_tags": return L10n.conditionNew
        case "like_new": return L10n.conditionLikeNew
        case "good": return L10n.conditionGood
        case "fair": return L10n.conditionFair
        default: return raw
        }
    }
}
