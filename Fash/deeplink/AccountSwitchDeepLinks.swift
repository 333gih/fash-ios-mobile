import Foundation

struct AccountSwitchPrompt: Equatable {
    let pendingUserId: String
    let emailMasked: String?
    let unreadCount: Int
}

/// Port of Android `AccountSwitchDeepLinks`.
enum AccountSwitchDeepLinks {
    static let fcmType = "account.notification_pending"

    static func parseFromFcmData(_ data: [String: String]) -> AccountSwitchPrompt? {
        guard data["type"] == fcmType else { return nil }
        let userId = data["pending_user_id"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !userId.isEmpty else { return nil }
        let email = data["pending_email_masked"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let unread = max(Int(data["unread_count"] ?? "") ?? 1, 1)
        return AccountSwitchPrompt(
            pendingUserId: userId,
            emailMasked: (email?.isEmpty == false) ? email : nil,
            unreadCount: unread
        )
    }
}
