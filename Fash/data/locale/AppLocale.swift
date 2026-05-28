import Foundation
import Observation
import SwiftUI

/// Mirrors Android [AppLocale] — vi default, en optional; drives API path prefix + Bundle locale.
@Observable
final class AppLocaleController {
    static let shared = AppLocaleController()

    static let tagVI = "vi"
    static let tagEN = "en"

    private static let prefsKey = "app_language_tag"

    private(set) var revision = 0
    private(set) var currentTag: String = tagVI

    /// Called after the user changes in-app language (settings / login toggle).
    var onLocaleChanged: ((String) -> Void)?

    var locale: Locale {
        Locale(identifier: currentTag == Self.tagEN ? "en" : "vi")
    }

    private init() {}

    func coreApiPathSegment() -> String { currentTag }

    func applyPersistedOrDefault() {
        if let saved = UserDefaults.standard.string(forKey: Self.prefsKey) {
            currentTag = Self.normalize(saved)
        } else {
            let preferred = Locale.preferredLanguages.first ?? Self.tagVI
            currentTag = preferred.lowercased().hasPrefix("en") ? Self.tagEN : Self.tagVI
            UserDefaults.standard.set(currentTag, forKey: Self.prefsKey)
        }
    }

    func setLocale(_ tag: String) {
        let normalized = Self.normalize(tag)
        guard normalized != currentTag else { return }
        currentTag = normalized
        UserDefaults.standard.set(normalized, forKey: Self.prefsKey)
        L10n.invalidateCache()
        revision += 1
        onLocaleChanged?(normalized)
    }

    private static func normalize(_ raw: String) -> String {
        raw.lowercased().hasPrefix(tagEN) ? tagEN : tagVI
    }
}

enum AppLocale {
    static var currentTag: String { AppLocaleController.shared.currentTag }
    static var locale: Locale { AppLocaleController.shared.locale }
    static let tagVI = AppLocaleController.tagVI
    static let tagEN = AppLocaleController.tagEN

    static func coreApiPathSegment() -> String { AppLocaleController.shared.coreApiPathSegment() }

    static func applyPersistedOrDefault() {
        AppLocaleController.shared.applyPersistedOrDefault()
    }

    static func setLocale(_ tag: String) {
        AppLocaleController.shared.setLocale(tag)
    }
}
