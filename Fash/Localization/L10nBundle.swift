import Foundation

extension L10n {
    private static var stringsBundle: Bundle {
        let tag = AppLocale.currentTag
        let candidates = [
            Bundle.main.path(forResource: tag, ofType: "lproj"),
            Bundle.main.path(forResource: tag, ofType: "lproj", inDirectory: "Resources"),
        ]
        for path in candidates.compactMap({ $0 }) {
            if let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return Bundle.main
    }

    static func t(_ key: String) -> String {
        let value = stringsBundle.localizedString(forKey: key, value: nil, table: nil)
        if !value.isEmpty, value != key { return value }
        if AppLocale.currentTag == AppLocale.tagEN,
           let viPath = Bundle.main.path(forResource: AppLocale.tagVI, ofType: "lproj"),
           let viBundle = Bundle(path: viPath) {
            let viValue = viBundle.localizedString(forKey: key, value: nil, table: nil)
            if !viValue.isEmpty, viValue != key { return viValue }
        }
        return NSLocalizedString(key, bundle: stringsBundle, comment: "")
    }
}
