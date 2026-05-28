import Foundation

extension L10n {
    private static let stringsTable = "Localizable"

    /// Clears cached bundles/tables when the user switches VN/EN.
    static func invalidateCache() {
        L10nStringTableStore.shared.clear()
    }

    static func t(_ key: String) -> String {
        let tag = AppLocale.currentTag
        if let value = resolve(key, tag: tag), isUsable(value, for: key) {
            return value
        }
        if tag == AppLocale.tagEN,
           let value = resolve(key, tag: AppLocale.tagVI),
           isUsable(value, for: key) {
            return value
        }
        return key
    }

    private static func isUsable(_ value: String, for key: String) -> Bool {
        !value.isEmpty && value != key
    }

    private static func resolve(_ key: String, tag: String) -> String? {
        L10nStringTableStore.shared.lookup(key, tag: tag)
    }
}

/// Loads `Localizable.strings` from the app bundle (vi/en `.lproj`).
/// Supports layouts: `vi.lproj/`, `Resources/vi.lproj/`, and nested search under `Bundle.main`.
private final class L10nStringTableStore {
    static let shared = L10nStringTableStore()

    private let stringsFileName = "Localizable"
    private var tableCache: [String: [String: String]] = [:]
    private var stringsPathCache: [String: String] = [:]

    func clear() {
        tableCache.removeAll()
        stringsPathCache.removeAll()
    }

    func lookup(_ key: String, tag: String) -> String? {
        table(for: tag)[key]
    }

    private func table(for tag: String) -> [String: String] {
        if let cached = tableCache[tag] { return cached }

        var loaded: [String: String] = [:]
        defer { tableCache[tag] = loaded }

        guard let path = stringsPath(for: tag),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            return loaded
        }
        loaded = dict
        return loaded
    }

    private func stringsPath(for tag: String) -> String? {
        if let cached = stringsPathCache[tag] { return cached }
        let path = discoverLocalizableStringsPath(for: tag)
        if let path { stringsPathCache[tag] = path }
        return path
    }

    private func discoverLocalizableStringsPath(for tag: String) -> String? {
        let main = Bundle.main
        let lprojName = "\(tag).lproj"
        let relativeDirs = [
            lprojName,
            "Resources/\(lprojName)",
        ]
        for dir in relativeDirs {
            if let path = main.path(forResource: stringsFileName, ofType: "strings", inDirectory: dir) {
                return path
            }
        }

        guard let resourceURL = main.resourceURL else { return nil }
        let suffix = "\(lprojName)/\(stringsFileName).strings"
        guard let enumerator = FileManager.default.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let url as URL in enumerator {
            guard url.path.hasSuffix(suffix) else { continue }
            return url.path
        }
        return nil
    }
}
