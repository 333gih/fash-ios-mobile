import Foundation

/// Port of Android `SocialAuthCacheClear` (data.auth).
enum SocialAuthCacheClear {
    @MainActor
    static func clearCachedSocialSignInForLogout() {
        GoogleSignInClients.signOut()
    }
}
