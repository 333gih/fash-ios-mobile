import Foundation

/// Append-only, session-scoped store of every feed item ever loaded for one tab.
/// Items are never removed — provides the full dataset for scroll-back recovery without server round-trips.
struct FeedGlobalItemStore {
    private(set) var allItems: [ListingFeedItem] = []
    private var idToGlobalIndex: [String: Int] = [:]

    var count: Int { allItems.count }
    var isEmpty: Bool { allItems.isEmpty }

    /// Append items whose IDs are not yet in `knownIds`. Returns count added.
    @discardableResult
    mutating func appendNew(_ items: [ListingFeedItem], knownIds: inout Set<String>) -> Int {
        var added = 0
        for item in items {
            if knownIds.insert(item.id).inserted {
                idToGlobalIndex[item.id] = allItems.count
                allItems.append(item)
                added += 1
            }
        }
        return added
    }

    /// Reset to a fresh first page and return the new knownIds set built from it.
    mutating func reset(with items: [ListingFeedItem]) -> Set<String> {
        allItems = []
        idToGlobalIndex = [:]
        var ids = Set<String>()
        ids.reserveCapacity(items.count)
        for item in items {
            if ids.insert(item.id).inserted {
                idToGlobalIndex[item.id] = allItems.count
                allItems.append(item)
            }
        }
        return ids
    }

    /// Items in the half-open global-index range [from, to).
    func items(from: Int, to: Int) -> [ListingFeedItem] {
        let s = max(0, from)
        let e = min(allItems.count, to)
        guard s < e else { return [] }
        return Array(allItems[s..<e])
    }

    /// Keep interaction state (like/save) in sync so scroll-back restore shows the latest UI state.
    @discardableResult
    mutating func patchItem(withId id: String, transform: (ListingFeedItem) -> ListingFeedItem) -> Bool {
        guard let idx = idToGlobalIndex[id] else { return false }
        allItems[idx] = transform(allItems[idx])
        return true
    }
}
