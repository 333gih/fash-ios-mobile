import Foundation

/// Decode listing feed JSON off the main actor — UI updates stay on `@MainActor`.
enum ListingFeedParseSupport {
    static func parseFeedItems(_ data: Data) async throws -> [ListingFeedItem] {
        try await Task.detached(priority: .userInitiated) {
            try ListingFeedJsonParser.parseFeed(data)
        }.value
    }

    static func parseItemsArray(_ rows: [[String: Any]]) async -> [ListingFeedItem] {
        await Task.detached(priority: .userInitiated) {
            ListingFeedJsonParser.parseItemsArray(rows)
        }.value
    }
}
