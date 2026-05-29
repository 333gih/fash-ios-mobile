import Foundation

/// Android `FeedFormatters.kt` — wire-safe listing labels for grid cards.
enum ListingFeedFormatters {
    private static let uuidPattern = try! NSRegularExpression(
        pattern: "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
    )

    /// Strips JSON blobs and bare UUIDs from API strings.
    static func sanitizeListingUiText(_ raw: String?) -> String {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{"),
           let data = trimmed.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let keys = ["display_name", "DisplayName", "name", "Name", "title", "Title"]
            for key in keys {
                if let value = object[key] as? String {
                    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleaned.isEmpty { return cleaned }
                }
            }
            return ""
        }
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        if uuidPattern.firstMatch(in: trimmed, range: range) != nil { return "" }
        return trimmed
    }

    /// Android `formatListingEngagementShort` — empty when `count <= 0`.
    static func formatEngagementShort(_ count: Int) -> String {
        guard count > 0 else { return "" }
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fk", Double(count) / 1_000) }
        return "\(count)"
    }
}
