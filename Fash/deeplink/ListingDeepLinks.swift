import Foundation

/// Port of Android `ListingDeepLinks` (deeplink).
enum ListingDeepLinks {
    /// `fash://listing/{listingId}` — opens listing when app is installed.
    static func fashListingURL(listingId: String) -> URL? {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard id.count >= 8 else { return nil }
        return URL(string: "fash://listing/\(id)")
    }
}
