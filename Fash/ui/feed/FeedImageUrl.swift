import Foundation

/// Port of Android `FeedImageUrl` (ui.feed).
enum FeedImageUrl {
    static func resolveListingImageUrl(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.lowercased().hasPrefix("http") { return trimmed }
        let base = AppEnvironment.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.hasPrefix("/") { return "\(base)\(trimmed)" }
        return "\(base)/\(trimmed)"
    }

    static func resolveProfileImageUrl(_ path: String) -> String {
        resolveListingImageUrl(path)
    }

    static func resolveProfileImageUrlOrNil(_ path: String?) -> String? {
        guard let path = path?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else { return nil }
        let resolved = resolveListingImageUrl(path)
        return resolved.isEmpty ? nil : resolved
    }

    static func resolveListingImageUrlOrNil(_ path: String?) -> String? {
        resolveProfileImageUrlOrNil(path)
    }
}
