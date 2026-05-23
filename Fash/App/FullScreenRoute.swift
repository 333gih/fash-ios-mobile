import SwiftUI

enum FullScreenRoute: Identifiable {
    case listing(String)
    case seller(String)
    case editProfile
    case chat(String)
    case orders
    case order(String)
    case checkout(String)
    case inviteFriends

    var id: String {
        switch self {
        case .listing(let id): return "listing-\(id)"
        case .seller(let u): return "seller-\(u)"
        case .editProfile: return "editProfile"
        case .chat(let id): return "chat-\(id)"
        case .orders: return "orders"
        case .order(let id): return "order-\(id)"
        case .checkout(let id): return "checkout-\(id)"
        case .inviteFriends: return "invite"
        }
    }
}

extension AppRouter {
    var fullScreenRoute: FullScreenRoute? {
        if let id = selectedListingId { return .listing(id) }
        if let user = sellerShopUsername { return .seller(user) }
        if showEditProfile { return .editProfile }
        if let conv = selectedConversationId { return .chat(conv) }
        if showOrdersScreen, selectedOrderId == nil { return .orders }
        if let orderId = selectedOrderId { return .order(orderId) }
        if let checkoutId = selectedCheckoutListingId { return .checkout(checkoutId) }
        if showInviteFriendsScreen { return .inviteFriends }
        return nil
    }

    func dismissFullScreen() {
        selectedListingId = nil
        sellerShopUsername = nil
        showEditProfile = false
        selectedConversationId = nil
        showOrdersScreen = false
        selectedOrderId = nil
        selectedCheckoutListingId = nil
        showInviteFriendsScreen = false
    }
}
