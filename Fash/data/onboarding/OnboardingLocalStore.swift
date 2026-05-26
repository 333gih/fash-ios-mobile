import Foundation

final class OnboardingLocalStore {
    private static let keyPrefix = "fash_onboard_"

    private func key(_ suffix: String, userId: String) -> String { "\(Self.keyPrefix)\(suffix)_\(userId)" }

    func skipSizingReference(userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: key("skip_sizing", userId: userId))
    }

    func setSkipSizingReference(userId: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key("skip_sizing", userId: userId))
    }

    /// Clears persisted onboarding skip flags (e.g. on logout). Android [OnboardingLocalStore.clearAll].
    func clearAll() {
        let defaults = UserDefaults.standard
        for entry in defaults.dictionaryRepresentation().keys where entry.hasPrefix(Self.keyPrefix) {
            defaults.removeObject(forKey: entry)
        }
    }
}
