import Foundation
import SwiftUI

/// Mirrors Android [AppLocale] — vi default, en optional; drives API path prefix + Bundle locale.
enum AppLocale {
    static let tagVI = "vi"
    static let tagEN = "en"

    private static let prefsKey = "app_language_tag"
    private static var cachedTag: String = tagVI

    static var locale: Locale {
        Locale(identifier: currentTag == tagEN ? "en" : "vi")
    }

    static var currentTag: String { cachedTag }

    static func coreApiPathSegment() -> String { currentTag }

    static func applyPersistedOrDefault() {
        if let saved = UserDefaults.standard.string(forKey: prefsKey) {
            cachedTag = normalize(saved)
        } else {
            let preferred = Locale.preferredLanguages.first ?? tagVI
            cachedTag = preferred.lowercased().hasPrefix("en") ? tagEN : tagVI
            UserDefaults.standard.set(cachedTag, forKey: prefsKey)
        }
    }

    static func setLocale(_ tag: String) {
        cachedTag = normalize(tag)
        UserDefaults.standard.set(cachedTag, forKey: prefsKey)
    }

    private static func normalize(_ raw: String) -> String {
        raw.lowercased().hasPrefix(tagEN) ? tagEN : tagVI
    }
}
