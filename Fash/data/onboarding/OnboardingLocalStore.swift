import Foundation

final class OnboardingLocalStore {
    private static let keyPrefix = "fash_onboard_"

    private func key(_ suffix: String, userId: String) -> String {
        let id = userId.trimmingCharacters(in: .whitespaces).isEmpty ? "anonymous" : userId
        return "\(Self.keyPrefix)\(suffix)_\(id)"
    }

    func skippedAestheticTags(userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: key("skipped_aesthetic_tags", userId: userId))
    }

    func setSkippedAestheticTags(userId: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key("skipped_aesthetic_tags", userId: userId))
    }

    func skippedProfilePhoto(userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: key("skipped_profile_photo", userId: userId))
    }

    func setSkippedProfilePhoto(userId: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key("skipped_profile_photo", userId: userId))
    }

    func skippedSizing(userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: key("skipped_sizing", userId: userId))
    }

    func setSkippedSizing(userId: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key("skipped_sizing", userId: userId))
    }

    /// Legacy alias — Android [OnboardingLocalStore.skippedSizing].
    func skipSizingReference(userId: String) -> Bool { skippedSizing(userId: userId) }

    func setSkipSizingReference(userId: String, value: Bool) { setSkippedSizing(userId: userId, value: value) }

    /// Clears persisted onboarding skip flags (e.g. on logout). Android [OnboardingLocalStore.clearAll].
    func clearAll() {
        let defaults = UserDefaults.standard
        for entry in defaults.dictionaryRepresentation().keys where entry.hasPrefix(Self.keyPrefix) {
            defaults.removeObject(forKey: entry)
        }
    }
}
