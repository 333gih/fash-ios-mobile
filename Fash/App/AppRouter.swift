import Foundation
import Observation

/// Mirrors MainActivity navigation state (tabs + overlays).
enum MainTab: Int, CaseIterable {
    case home = 0
    case explore = 1
    case post = 2
    case chat = 3
    case profile = 4
}

enum LoginStep {
    case email
    case otp
}

enum OnboardingStep: String, CaseIterable {
    case aestheticTags
    case shoppingPreferences
    case profilePhoto
    case sizingReference
    case username
    case setupPassword
    case completed
}

@Observable
@MainActor
final class AppRouter {
    var showSplash = true
    var isLoggingOut = false
    var isGuestMode = false
    var loginStep: LoginStep?
    var setupGateFetchFailed = false
    var onboardingStep: OnboardingStep?
    var selectedTab: MainTab = .home

    // MainNav overlays
    var showNotificationScreen = false
    var notificationDetailId: String?
    var showSettingsScreen = false
    var showChangePasswordScreen = false
    var featureTourActive = false

    // Full-screen overlays
    var selectedListingId: String?
    var sellerShopUsername: String?
    var editListingId: String?
    var showEditProfile = false
    var selectedConversationId: String?
    var selectedOrderId: String?
    var showOrdersScreen = false
    var showShippingAddressList = false
    var showAddAddressScreen = false
    var selectedCheckoutListingId: String?
    var homeEditorialSlug: String?
    var showHomeDeliveringScreen = false
    var showSellerPackagesScreen = false
    var showFollowConnections = false
    var showFeaturedSellersAll = false
    var showInviteFriendsScreen = false
    var orderIdPendingCancel: String?

    var hasBlockingOverlay: Bool {
        selectedListingId != nil
            || sellerShopUsername != nil
            || editListingId != nil
            || showEditProfile
            || selectedConversationId != nil
            || selectedOrderId != nil
            || showOrdersScreen
            || showShippingAddressList
            || showAddAddressScreen
            || selectedCheckoutListingId != nil
            || homeEditorialSlug != nil
            || showHomeDeliveringScreen
            || showSellerPackagesScreen
            || showFollowConnections
            || showFeaturedSellersAll
            || showInviteFriendsScreen
            || orderIdPendingCancel != nil
    }

    func popOverlay() {
        if showChangePasswordScreen { showChangePasswordScreen = false; return }
        if orderIdPendingCancel != nil { orderIdPendingCancel = nil; return }
        if showInviteFriendsScreen { showInviteFriendsScreen = false; return }
        if showFeaturedSellersAll { showFeaturedSellersAll = false; return }
        if showFollowConnections { showFollowConnections = false; return }
        if showSellerPackagesScreen { showSellerPackagesScreen = false; return }
        if showHomeDeliveringScreen { showHomeDeliveringScreen = false; return }
        if homeEditorialSlug != nil { homeEditorialSlug = nil; return }
        if selectedCheckoutListingId != nil { selectedCheckoutListingId = nil; return }
        if showAddAddressScreen { showAddAddressScreen = false; return }
        if showShippingAddressList { showShippingAddressList = false; return }
        if selectedOrderId != nil { selectedOrderId = nil; return }
        if showOrdersScreen { showOrdersScreen = false; return }
        if selectedConversationId != nil { selectedConversationId = nil; return }
        if showEditProfile { showEditProfile = false; return }
        if editListingId != nil { editListingId = nil; return }
        if sellerShopUsername != nil { sellerShopUsername = nil; return }
        if selectedListingId != nil { selectedListingId = nil; return }
    }
}
