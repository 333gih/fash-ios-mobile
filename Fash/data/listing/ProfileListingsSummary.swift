import Foundation

/// Tab badge counts from `GET /users/me/listings/summary` — no listing hydration.
struct ProfileListingsSummary: Equatable {
    var active = 0
    var inReview = 0
    var rejected = 0
    var sold = 0
    var wishlist = 0

    static func parse(from root: [String: Any]) -> ProfileListingsSummary {
        func int(_ keys: String...) -> Int {
            for key in keys {
                if let n = root[key] as? NSNumber {
                    return min(max(n.intValue, 0), 50_000)
                }
            }
            return 0
        }
        return ProfileListingsSummary(
            active: int("active", "Active"),
            inReview: int("in_review", "inReview", "InReview"),
            rejected: int("rejected", "Rejected"),
            sold: int("sold", "Sold"),
            wishlist: int("wishlist", "Wishlist")
        )
    }
}
