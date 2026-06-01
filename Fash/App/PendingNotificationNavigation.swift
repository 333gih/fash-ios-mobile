import Foundation

/// Navigation target queued while the notification full-screen cover dismisses.
enum PendingNotificationNavigation: Equatable {
    case orders
    case listing(String)
    case chat(String)
    case followConnections(Int)
    case explore
    case inviteFriends
}

extension AppRouter {
    /// Stored outside `@Observable` — closures are not diffable.
    static var pendingAfterNotificationDismiss: (@MainActor () -> Void)?

    func dismissNotificationsAndNavigate(_ target: PendingNotificationNavigation) {
        pendingNotificationNavigation = target
        Self.pendingAfterNotificationDismiss = nil
        notificationDetailId = nil
        showNotificationScreen = false
    }

    func dismissNotifications(afterDismiss: @escaping @MainActor () -> Void) {
        pendingNotificationNavigation = nil
        Self.pendingAfterNotificationDismiss = afterDismiss
        notificationDetailId = nil
        showNotificationScreen = false
    }

    func consumePendingNotificationNavigation(deps: AppDependencies) {
        if let afterDismiss = Self.pendingAfterNotificationDismiss {
            Self.pendingAfterNotificationDismiss = nil
            afterDismiss()
            return
        }
        guard let target = pendingNotificationNavigation else { return }
        pendingNotificationNavigation = nil
        switch target {
        case .orders:
            selectedTab = .orders
        case .listing(let listingId):
            deps.presentListingDetail(listingId: listingId, router: self)
        case .chat(let conversationId):
            selectedTab = .chat
            selectedConversationId = conversationId
        case .followConnections(let tab):
            followConnectionsInitialTab = tab
            showFollowConnections = true
        case .explore:
            showExploreOverlay = true
        case .inviteFriends:
            showInviteFriendsScreen = true
        }
    }
}
