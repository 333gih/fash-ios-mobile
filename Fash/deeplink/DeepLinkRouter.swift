import Foundation

enum DeepLinkRouter {
    static func handle(url: URL, router: AppRouter, deps: AppDependencies) {
        if url.scheme == "fash" {
            handleFashScheme(url: url, router: router, deps: deps)
            return
        }
        if let host = url.host, host.contains("fash") {
            handleHttps(url: url, router: router)
        }
    }

    private static func handleFashScheme(url: URL, router: AppRouter, deps: AppDependencies) {
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch url.host {
        case "listing":
            router.selectedListingId = path
        case "profile":
            router.sellerShopUsername = path
        case "inbox":
            router.showNotificationScreen = true
            router.notificationDetailId = path
        case "invite":
            router.showInviteFriendsScreen = true
        default:
            break
        }
    }

    private static func handleHttps(url: URL, router: AppRouter) {
        let parts = url.pathComponents.filter { $0 != "/" }
        if parts.count >= 3, parts[1] == "l" {
            router.selectedListingId = parts[2]
        }
        if parts.count >= 3, parts[1] == "u" {
            router.sellerShopUsername = parts[2]
        }
        if url.path.contains("invite") {
            router.showInviteFriendsScreen = true
        }
    }
}
