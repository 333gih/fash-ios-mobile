import Foundation

final class OnboardingLocalStore {
    private func key(_ suffix: String, userId: String) -> String { "fash_onboard_\(suffix)_\(userId)" }
    func skipSizingReference(userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: key("skip_sizing", userId: userId))
    }
    func setSkipSizingReference(userId: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key("skip_sizing", userId: userId))
    }
}
