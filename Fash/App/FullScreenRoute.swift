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
    case notificationPreferences
    case editorialList
    case uxSurvey(String)
    case sellerPackageCheckout(SellerProductPackage)
    case chatOrderDetail(String)

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
        case .notificationPreferences: return "notificationPreferences"
        case .editorialList: return "editorialList"
        case .uxSurvey(let key): return "uxSurvey-\(key)"
        case .sellerPackageCheckout(let pkg): return "pkgCheckout-\(pkg.code)"
        case .chatOrderDetail(let id): return "chatOrder-\(id)"
        }
    }
}

extension AppRouter {
    /// Listing id shown on top of Explore overlay — `ExploreOverlayHost` presents PDP; RootView skips duplicate cover.
    var exploreOverlayListingId: String? {
        guard showExploreOverlay else { return nil }
        let id = selectedListingId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return id.isEmpty ? nil : id
    }

    /// Priority matches Android MainActivity overlay back stack (outermost first).
    var fullScreenRoute: FullScreenRoute? {
        if exploreOverlayListingId != nil { return nil }
        if let id = selectedListingId { return .listing(id) }
        if let user = sellerShopUsername { return .seller(user) }
        if let editId = editListingId { return .editListing(editId) }
        if showEditProfile { return .editProfile }
        if let conv = selectedConversationId { return .chat(conv) }
        if showChangePasswordScreen { return .changePassword }
        if showNotificationPreferencesScreen { return .notificationPreferences }
        if showOrdersScreen, selectedOrderId == nil { return .orders }
        if let orderId = selectedOrderId { return .order(orderId) }
        if let checkoutId = selectedCheckoutListingId { return .checkout(checkoutId) }
        if showAddAddressScreen { return .addAddress }
        if showShippingAddressList { return .shippingAddresses }
        if let slug = homeEditorialSlug { return .homeEditorial(slug) }
        if showHomeDeliveringScreen { return .homeDelivering }
        if sellerPackageCheckout != nil { return .sellerPackageCheckout(sellerPackageCheckout!) }
        if showSellerPackagesScreen { return .sellerPackages }
        if showFollowConnections { return .followConnections }
        if showFeaturedSellersAll { return .featuredSellers }
        if showInviteFriendsScreen { return .inviteFriends }
        if chatOrderDetailOverlayId != nil { return .chatOrderDetail(chatOrderDetailOverlayId!) }
        if uxSurveyKey != nil { return .uxSurvey(uxSurveyKey!) }
        if showEditorialListScreen, homeEditorialSlug == nil { return .editorialList }
        return nil
    }

    func dismissFullScreen() {
        popOverlay()
    }
}
