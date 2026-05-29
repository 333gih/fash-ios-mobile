import Foundation
import UIKit

/// Applies admin-configured button actions — Android `AppPromoNavigation`.
@MainActor
enum AppPromoNavigation {
    static func applyPrimary(campaign: AppPromoCampaign, router: AppRouter) {
        guard let action = campaign.primaryAction else { return }
        apply(action: action, router: router)
    }

    static func applySecondary(campaign: AppPromoCampaign, router: AppRouter) {
        guard let action = campaign.secondaryAction else { return }
        apply(action: action, router: router)
    }

    private static func apply(action: AppPromoButtonAction, router: AppRouter) {
        let type = action.type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let payload = action.payload.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case "external_url", "deeplink":
            guard !payload.isEmpty, let url = URL(string: payload) else { return }
            UIApplication.shared.open(url)
        case "in_app_explore":
            router.exploreSearchExpanded = false
            router.showExploreOverlay = true
        case "in_app_orders":
            router.selectedTab = .orders
        case "in_app_chat":
            router.selectedTab = .chat
        case "in_app_post_tab":
            router.selectedTab = .post
        case "in_app_invite_friends":
            router.showInviteFriendsScreen = true
        case "in_app_product_packages":
            router.sellerPackageCheckout = nil
            router.showSellerPackagesScreen = true
        case "in_app_editorial_guides":
            if !payload.isEmpty {
                router.showEditorialListScreen = false
                router.homeEditorialSlug = payload
            } else {
                router.homeEditorialSlug = nil
                router.showEditorialListScreen = true
            }
        case "in_app_ux_survey":
            router.uxSurveyKey = payload.isEmpty ? "fash_ux_v1" : payload
        case "in_app_listing":
            guard !payload.isEmpty else { return }
            AppDependencies.shared.presentListingDetail(listingId: payload, router: router)
        default:
            break
        }
    }
}
