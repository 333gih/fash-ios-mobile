import Foundation

extension L10n {
    static func t(_ key: String) -> String {
        let tag = AppLocale.currentTag
        if let path = Bundle.main.path(forResource: tag, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return NSLocalizedString(key, comment: "")
    }
}
