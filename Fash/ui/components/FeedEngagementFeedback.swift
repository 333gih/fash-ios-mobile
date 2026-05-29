import Foundation

/// Snackbar copy for like / save / follow — Android `listing_*_snackbar` + `follow_success`.
enum FeedEngagementFeedback {
    static func likeMessage(liked: Bool) -> String {
        liked ? L10n.listingLikeAddedSnackbar : L10n.listingLikeRemovedSnackbar
    }

    static func saveMessage(saved: Bool) -> String {
        saved ? L10n.listingSaveAddedSnackbar : L10n.listingSaveRemovedSnackbar
    }

    static func actionErrorMessage(for error: Error) -> String {
        let msg = FashErrorPresentation.userMessage(for: error)
        return msg.isEmpty ? L10n.feedActionError : msg
    }
}
