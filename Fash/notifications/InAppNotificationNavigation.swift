import Foundation

/// Resolves in-app banner taps to navigation targets (chat-first for marketplace threads).
@MainActor
enum InAppNotificationNavigation {
    /// Conversation to open when payload is chat / deal / message related.
    static func chatConversationId(from data: [String: String]) -> String? {
        guard let conv = ChatInAppNotificationPolicy.conversationId(from: data) else { return nil }
        let nav = normalized(data["nav_target"] ?? data["navTarget"])
        let screen = normalized(data["screen"])
        let type = normalized(data["type"])
        let event = normalized(data["event"])

        if nav == "chat" || screen == "chat" { return conv }
        if ChatInAppNotificationPolicy.isChatRelatedType(type) { return conv }
        if ChatInAppNotificationPolicy.isChatRelatedType(event) { return conv }
        if type.hasPrefix("meeting_") || event.hasPrefix("meeting_") || event == "deal_complete_nudge" {
            return conv
        }
        if ChatInAppNotificationPolicy.isChatRelated(data: data) { return conv }
        return nil
    }

    static func orderId(from data: [String: String]) -> String? {
        for key in ["order_id", "marketplace_order_id", "orderId"] {
            let value = data[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty { return value }
        }
        return nil
    }

    static func openChat(conversationId: String, router: AppRouter, deps: AppDependencies) {
        let cid = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return }

        deps.listingPreview.close(deps: deps, animated: false)
        router.showNotificationScreen = false
        router.notificationDetailId = nil
        router.pendingNotificationNavigation = nil
        AppRouter.pendingAfterNotificationDismiss = nil
        router.showExploreOverlay = false
        router.exploreSearchExpanded = false
        router.listingDetailRootId = nil
        router.listingDetailPath = []
        router.sellerShopUsername = nil
        router.editListingId = nil
        router.showEditProfile = false
        router.selectedOrderId = nil
        router.showOrdersScreen = false
        router.selectedCheckoutListingId = nil
        router.chatOrderDetailOverlayId = nil
        router.homeEditorialSlug = nil
        router.showHomeDeliveringScreen = false
        router.showInviteFriendsScreen = false
        router.showFollowConnections = false
        router.showFeaturedSellersAll = false

        router.selectedTab = .chat
        router.selectedConversationId = cid
        ChatNotificationPresence.registerOpenConversation(cid, deps: deps)
    }

    static func openOrder(orderId: String, router: AppRouter, deps: AppDependencies) {
        let oid = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !oid.isEmpty else { return }
        deps.listingPreview.close(deps: deps, animated: false)
        router.showNotificationScreen = false
        router.notificationDetailId = nil
        router.selectedConversationId = nil
        router.showOrdersScreen = false
        router.selectedTab = .orders
        router.selectedOrderId = oid
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    }
}
