import Foundation

@MainActor
enum DeepLinkRouter {
    static func handle(url: URL, router: AppRouter, deps: AppDependencies) {
        if url.scheme == "fash" {
            handleFashScheme(url: url, router: router, deps: deps)
            return
        }
        if url.host?.contains("fash") == true {
            handleHttps(url: url, router: router, deps: deps)
        }
    }

    private static func handleFashScheme(url: URL, router: AppRouter, deps: AppDependencies) {
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        switch url.host {
        case "listing":
            deps.pendingDeepLinkListingId = path
            router.selectedListingId = path
        case "profile":
            deps.pendingDeepLinkSellerUsername = path
            router.sellerShopUsername = path
        case "inbox":
            deps.pendingInboxNotificationId = path
            router.showNotificationScreen = true
            router.notificationDetailId = path
        case "invite":
            deps.pendingOpenInviteFriends = true
            deps.pendingReferralToken = components?.queryItems?.first(where: { $0.name == "r" })?.value
            deps.pendingReferrerUsername = components?.queryItems?.first(where: { $0.name == "ref" })?.value
            router.showInviteFriendsScreen = true
        default:
            break
        }
    }

    private static func handleHttps(url: URL, router: AppRouter, deps: AppDependencies) {
        let parts = url.pathComponents.filter { $0 != "/" }
        if parts.count >= 3, parts[1] == "l" {
            let id = parts[2]
            deps.pendingDeepLinkListingId = id
            router.selectedListingId = id
        }
        if parts.count >= 3, parts[1] == "u" {
            let user = parts[2]
            deps.pendingDeepLinkSellerUsername = user
            router.sellerShopUsername = user
        }
        if url.path.contains("invite") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            deps.pendingReferralToken = components?.queryItems?.first(where: { $0.name == "r" })?.value
            deps.pendingReferrerUsername = components?.queryItems?.first(where: { $0.name == "ref" })?.value
            deps.pendingOpenInviteFriends = true
            router.showInviteFriendsScreen = true
        }
    }
}
