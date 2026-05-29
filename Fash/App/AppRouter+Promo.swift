import Foundation
import UIKit

extension AppRouter {
    func handlePromoSlideClick(_ slide: FashPromoSlideDef) {
        if showExploreOverlay {
            showExploreOverlay = false
            exploreSearchExpanded = false
        }
        let navType = slide.navigationType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let payload = slide.navigationPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        switch navType {
        case "", "none":
            break
        case "in_app_explore":
            exploreSearchExpanded = false
            showExploreOverlay = true
        case "in_app_orders":
            selectedTab = .orders
        case "in_app_chat":
            selectedTab = .chat
        case "in_app_product_packages":
            sellerPackageCheckout = nil
            showSellerPackagesScreen = true
        case "in_app_invite_friends":
            showInviteFriendsScreen = true
        case "in_app_editorial_guides":
            if !payload.isEmpty {
                showEditorialListScreen = false
                homeEditorialSlug = payload
            } else {
                homeEditorialSlug = nil
                showEditorialListScreen = true
            }
        case "in_app_ux_survey":
            uxSurveyKey = payload.isEmpty ? "fash_ux_v1" : payload
        case "external_url", "deeplink":
            guard !payload.isEmpty, let url = URL(string: payload) else { break }
            UIApplication.shared.open(url)
        default:
            break
        }
    }
}
