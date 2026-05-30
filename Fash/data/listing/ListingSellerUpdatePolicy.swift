import Foundation

/// Core seller `PUT /listings/:id` guard — Android `ListingSellerUpdatePolicy.kt`.
func isListingStatusSellerPutAllowed(_ status: String?) -> Bool {
    let s = status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    if s.isEmpty { return true }
    return s == "in_review" || s == "rejected" || s == "active"
}

func editListingReadOnlyBannerMessage(status: String) -> String {
    if status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "inactive" {
        return L10n.editListingReadonlyInactive
    }
    return L10n.editListingReadonlyLocked
}
