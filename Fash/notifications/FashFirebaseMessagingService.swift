import Foundation

/// Port of Android `FashFirebaseMessagingService` — parses FCM `data` payload and routes deep links.
enum FashFirebaseMessagingService {
    static func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        let data = stringDataMap(from: userInfo)
        routeFromPushData(data)
    }

    @MainActor
    static func handleForegroundNotification(userInfo: [AnyHashable: Any]) {
        let data = stringDataMap(from: userInfo)
        guard isNotificationForLoggedInUser(data) else { return }

        if data["inbox_refresh"] == "1" {
            AppDependencies.shared.requestOpenNotificationInbox()
        }

        let title = data["title"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = data["body"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let title, !title.isEmpty {
            AppDependencies.shared.inAppNotification = FashInAppNotificationSession(
                title: title,
                body: body,
                userNotificationId: data["user_notification_id"]
            )
        }
    }

    private static func routeFromPushData(_ data: [String: String]) {
        Task { @MainActor in
            let deps = AppDependencies.shared
            if let deepLink = data["deep_link"]?.trimmingCharacters(in: .whitespacesAndNewlines), !deepLink.isEmpty,
               let url = URL(string: deepLink) {
                if let router = deps.navigationRouter {
                    DeepLinkRouter.handle(url: url, router: router, deps: deps)
                } else {
                    storePendingDeepLink(url: url, deps: deps)
                }
                return
            }
            if let inboxId = data["user_notification_id"]?.trimmingCharacters(in: .whitespacesAndNewlines), !inboxId.isEmpty {
                deps.pendingInboxNotificationId = inboxId
                deps.navigationRouter?.showNotificationScreen = true
                deps.navigationRouter?.notificationDetailId = inboxId
            }
        }
    }

    @MainActor
    private static func storePendingDeepLink(url: URL, deps: AppDependencies) {
        guard url.scheme == "fash" else { return }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch url.host {
        case "listing":
            deps.pendingDeepLinkListingId = path
        case "profile":
            deps.pendingDeepLinkSellerUsername = path
        case "inbox":
            deps.pendingInboxNotificationId = path
        default:
            break
        }
    }

    @MainActor
    private static func isNotificationForLoggedInUser(_ data: [String: String]) -> Bool {
        let sessionUid = AppDependencies.shared.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if sessionUid.isEmpty { return true }
        let recipient = data["recipient_user_id"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if recipient.isEmpty { return true }
        return sessionUid.caseInsensitiveCompare(recipient) == .orderedSame
    }

    private static func stringDataMap(from userInfo: [AnyHashable: Any]) -> [String: String] {
        var out: [String: String] = [:]
        for (key, value) in userInfo {
            guard let key = key as? String else { continue }
            if key.hasPrefix("gcm.") || key.hasPrefix("google.") { continue }
            if let string = value as? String {
                out[key] = string
            } else if let number = value as? NSNumber {
                out[key] = number.stringValue
            }
        }
        return out
    }
}
