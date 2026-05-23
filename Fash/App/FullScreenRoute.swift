import SwiftUI

enum FullScreenRoute: Identifiable {
    case listing(String)
    case seller(String)
    case editListing(String)
    case editProfile
    case chat(String)
    case orders
    case order(String)
    case checkout(String)
    case shippingAddresses
    case addAddress
    case homeEditorial(String)
    case homeDelivering
    case sellerPackages
    case followConnections
    case featuredSellers
    case inviteFriends
    case changePassword

    var id: String {
        switch self {
        case .listing(let id): return "listing-\(id)"
        case .seller(let u): return "seller-\(u)"
        case .editListing(let id): return "edit-listing-\(id)"
        case .editProfile: return "editProfile"
        case .chat(let id): return "chat-\(id)"
        case .orders: return "orders"
        case .order(let id): return "order-\(id)"
        case .checkout(let id): return "checkout-\(id)"
        case .shippingAddresses: return "addresses"
        case .addAddress: return "addAddress"
        case .homeEditorial(let slug): return "editorial-\(slug)"
        case .homeDelivering: return "delivering"
        case .sellerPackages: return "sellerPackages"
        case .followConnections: return "follow"
        case .featuredSellers: return "featuredSellers"
        case .inviteFriends: return "invite"
        case .changePassword: return "changePassword"
        }
    }
}

extension AppRouter {
    /// Priority matches Android MainActivity overlay back stack (outermost first).
    var fullScreenRoute: FullScreenRoute? {
        if let id = selectedListingId { return .listing(id) }
        if let user = sellerShopUsername { return .seller(user) }
        if let editId = editListingId { return .editListing(editId) }
        if showEditProfile { return .editProfile }
        if let conv = selectedConversationId { return .chat(conv) }
        if showChangePasswordScreen { return .changePassword }
        if showOrdersScreen, selectedOrderId == nil { return .orders }
        if let orderId = selectedOrderId { return .order(orderId) }
        if let checkoutId = selectedCheckoutListingId { return .checkout(checkoutId) }
        if showAddAddressScreen { return .addAddress }
        if showShippingAddressList { return .shippingAddresses }
        if let slug = homeEditorialSlug { return .homeEditorial(slug) }
        if showHomeDeliveringScreen { return .homeDelivering }
        if showSellerPackagesScreen { return .sellerPackages }
        if showFollowConnections { return .followConnections }
        if showFeaturedSellersAll { return .featuredSellers }
        if showInviteFriendsScreen { return .inviteFriends }
        return nil
    }

    func dismissFullScreen() {
        popOverlay()
    }
}
