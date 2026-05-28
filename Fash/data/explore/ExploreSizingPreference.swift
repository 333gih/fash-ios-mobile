import Foundation

/// Persists Explore "Match my size" toggle — Android [ExploreSizingPreference].
enum ExploreSizingPreference {
    private static let key = "explore_sizing_mode"
    static let modeAll = "all"
    static let modeMatchProfile = "match_profile"

    static func read() -> String {
        let raw = UserDefaults.standard.string(forKey: key) ?? modeAll
        return raw.lowercased() == modeMatchProfile ? modeMatchProfile : modeAll
    }

    static func write(_ mode: String) {
        let normalized = mode.lowercased() == modeMatchProfile ? modeMatchProfile : modeAll
        UserDefaults.standard.set(normalized, forKey: key)
    }

    static func activeSizingModeForRecommendations() -> String? {
        let mode = read()
        return mode == modeMatchProfile ? modeMatchProfile : nil
    }
}
