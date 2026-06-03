import Foundation
import Observation

/// Mirrors MainActivity navigation state (tabs + overlays).
enum MainTab: Int, CaseIterable {
    case home = 0
    case orders = 1
    case post = 2
    case chat = 3
    case profile = 4

    var isGuestLocked: Bool {
        switch self {
        case .orders, .post, .chat, .profile: return true
        default: return false
        }
    }
}

enum LoginStep {
    case email
    case otp
}

struct ProfileEditReturnContext: Equatable {
    let tab: Int
    let listingId: String
}

struct ExploreProfileFilterRequest: Equatable {
    var categoryId: String?
    var brandId: String?
    var aestheticTagId: String?
    var searchQuery: String = ""
    var countryId: String?
    var countryIso2: String?
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
    /// True while Home / Explore prefetch runs after auth (login, onboarding complete).
    var isLaunchWarmupInProgress = false
    var isLoggingOut = false
    var isGuestMode = false
    var loginStep: LoginStep?
    var setupGateFetchFailed = false
    var onboardingStep: OnboardingStep?
    var selectedTab: MainTab = .home
    var showExploreOverlay = false
    var exploreSearchExpanded = false
    var pendingExploreProfileFilter: ExploreProfileFilterRequest?

    // MainNav overlays
    var showNotificationScreen = false
    var notificationDetailId: String?
    var pendingNotificationNavigation: PendingNotificationNavigation?
    var showSettingsScreen = false
    var showChangePasswordScreen = false
    var showNotificationPreferencesScreen = false
    var featureTourActive = false

    // Full-screen overlays
    /// Root listing for PDP full-screen flow (`listingDetailPath` stacks related picks).
    var listingDetailRootId: String?
    var listingDetailPath: [String] = []
    var selectedListingId: String? {
        get { listingDetailRootId }
        set {
            if let id = newValue?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
                openListingDetailFlow(rootId: id)
            } else {
                closeListingDetailFlow()
            }
        }
    }
    var sellerShopUsername: String?
    var editListingId: String?
    var profileEditReturn: ProfileEditReturnContext?
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
    var followConnectionsInitialTab = 0
    var showFeaturedSellersAll = false
    var showInviteFriendsScreen = false
    var showEditorialListScreen = false
    var uxSurveyKey: String?
    /// Package checkout/detail overlay — Android `sellerPackageCheckout`.
    var sellerPackageCheckout: SellerProductPackage?
    var chatOrderDetailOverlayId: String?
    var orderIdPendingCancel: String?
    /// Set when closing listing preview sheet before opening product detail.
    var pendingListingIdAfterPreview: String?

    var hasBlockingOverlay: Bool {
        listingDetailRootId != nil
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
            || showEditorialListScreen
            || uxSurveyKey != nil
            || sellerPackageCheckout != nil
            || chatOrderDetailOverlayId != nil
            || orderIdPendingCancel != nil
    }

    func popOverlay() {
        if chatOrderDetailOverlayId != nil { chatOrderDetailOverlayId = nil; return }
        if sellerPackageCheckout != nil { sellerPackageCheckout = nil; return }
        if uxSurveyKey != nil { uxSurveyKey = nil; return }
        if showEditorialListScreen { showEditorialListScreen = false; return }
        if showChangePasswordScreen { showChangePasswordScreen = false; return }
        if showNotificationPreferencesScreen { showNotificationPreferencesScreen = false; return }
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
        if listingDetailRootId != nil {
            popListingDetail()
            return
        }
    }

    func openListingDetailFlow(rootId: String) {
        let id = rootId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        listingDetailRootId = id
        listingDetailPath = []
    }

    func pushListingDetail(_ listingId: String) {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        guard listingDetailRootId != nil else {
            openListingDetailFlow(rootId: id)
            return
        }
        if listingDetailRootId?.caseInsensitiveCompare(id) == .orderedSame {
            // Re-selecting the flow root pops back to the first PDP.
            listingDetailPath = []
            return
        }
        if let existingIndex = listingDetailPath.firstIndex(where: { $0.caseInsensitiveCompare(id) == .orderedSame }) {
            // If the tapped item already exists in stack, pop back to it.
            listingDetailPath = Array(listingDetailPath.prefix(existingIndex + 1))
            return
        }
        listingDetailPath.append(id)
    }

    func popListingDetail() {
        if !listingDetailPath.isEmpty {
            listingDetailPath.removeLast()
            return
        }
        closeListingDetailFlow()
    }

    func closeListingDetailFlow(dismissExplore: Bool = false) {
        listingDetailRootId = nil
        listingDetailPath = []
        if dismissExplore || showExploreOverlay {
            showExploreOverlay = false
            exploreSearchExpanded = false
        }
    }
}
