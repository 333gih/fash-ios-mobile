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
        guard let bundle = L10nStringTableStore.shared.bundle(for: tag) else { return nil }

        let fromBundleAPI = bundle.localizedString(forKey: key, value: key, table: stringsTable)
        if isUsable(fromBundleAPI, for: key) { return fromBundleAPI }

        return L10nStringTableStore.shared.directLookup(key, tag: tag)
    }
}

/// Resolves `vi.lproj` / `en.lproj` inside the app bundle (supports root and `Resources/` layouts).
private final class L10nStringTableStore {
    static let shared = L10nStringTableStore()

    private let stringsTable = "Localizable"
    private var bundleCache: [String: Bundle] = [:]
    private var tableCache: [String: [String: String]] = [:]

    func clear() {
        bundleCache.removeAll()
        tableCache.removeAll()
    }

    func bundle(for tag: String) -> Bundle? {
        if let cached = bundleCache[tag] { return cached }
        guard let url = discoverLprojURL(for: tag) else { return nil }
        guard let bundle = Bundle(url: url) else { return nil }
        bundleCache[tag] = bundle
        return bundle
    }

    func directLookup(_ key: String, tag: String) -> String? {
        table(for: tag)[key]
    }

    private func table(for tag: String) -> [String: String] {
        if let cached = tableCache[tag] { return cached }

        var loaded: [String: String] = [:]
        defer { tableCache[tag] = loaded }

        guard let bundle = bundle(for: tag),
              let path = bundle.path(forResource: stringsTable, ofType: "strings"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            return loaded
        }
        loaded = dict
        return loaded
    }

    private func discoverLprojURL(for tag: String) -> URL? {
        let main = Bundle.main
        let directCandidates = [
            main.url(forResource: tag, withExtension: "lproj"),
            main.url(forResource: tag, withExtension: "lproj", subdirectory: "Resources"),
        ]
        for url in directCandidates.compactMap({ $0 }) {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                return url
            }
        }

        guard let resourceURL = main.resourceURL else { return nil }
        return findLprojDirectory(named: "\(tag).lproj", under: resourceURL)
    }

    private func findLprojDirectory(named dirName: String, under root: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let url as URL in enumerator {
            guard url.lastPathComponent == dirName else { continue }
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                return url
            }
        }
        return nil
    }
}
