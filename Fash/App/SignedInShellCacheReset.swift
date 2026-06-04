import Foundation

/// Clears in-memory shell caches when the authenticated account changes (login / social switch).
@MainActor
enum SignedInShellCacheReset {
    static func prepareForNewSession(
        deps: AppDependencies,
        homeVM: HomeViewModel,
        profileVM: ProfileViewModel,
        chatVM: ChatViewModel,
        exploreVM: ExploreViewModel,
        previousUserId: String?
    ) {
        let nextId = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let prev = previousUserId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let accountChanged = !prev.isEmpty && !nextId.isEmpty && prev.caseInsensitiveCompare(nextId) != .orderedSame
        let freshLogin = prev.isEmpty && !nextId.isEmpty
        guard accountChanged || freshLogin else { return }

        homeVM.clearCachesForSignedOutUser(deps: deps)
        profileVM.clearCachedProfile(deps: deps)
        chatVM.clearCachesForSignedOutUser()
        exploreVM.resetSessionOnOverlayClose()
        deps.invalidateSessionValidationForLogin()
    }
}
