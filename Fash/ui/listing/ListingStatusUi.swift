import Foundation

/// Marketplace status chip on grid cards — Android `ListingStatusUi.kt`.
enum ListingStatusUi {
    /// `suppressActive` — Home/Explore: hide noisy "active" chips; Profile grids pass `false`.
    static func overlayLabel(for wire: String?, suppressActive: Bool = false) -> String? {
        let trimmed = wire?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !trimmed.isEmpty else { return nil }
        if suppressActive, trimmed == "active" || trimmed == "inactive" { return nil }
        switch trimmed {
        case "in_review": return L10n.listingStatusInReview
        case "rejected": return L10n.listingStatusRejected
        case "active": return L10n.listingStatusActive
        case "inactive": return L10n.listingStatusInactive
        case "sold": return L10n.listingStatusSold
        case "reserved": return L10n.listingStatusReserved
        case "deleted": return L10n.listingStatusDeleted
        default: return wire?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
