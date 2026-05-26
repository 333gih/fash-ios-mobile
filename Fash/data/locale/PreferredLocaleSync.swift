import Foundation

/// Keeps `profiles.preferred_locale` in sync with the in-app language when the user is signed in.
final class PreferredLocaleSync {
    private let userRepository: UserRepository
    private let sessionStore: AuthSessionStore

    init(userRepository: UserRepository, sessionStore: AuthSessionStore) {
        self.userRepository = userRepository
        self.sessionStore = sessionStore
    }

    func syncIfSession(locale: String) async {
        guard sessionStore.read() != nil else { return }
        let tag = locale.lowercased().hasPrefix(AppLocale.tagEN) ? AppLocale.tagEN : AppLocale.tagVI
        _ = await userRepository.syncPreferredLocale(tag)
    }
}
