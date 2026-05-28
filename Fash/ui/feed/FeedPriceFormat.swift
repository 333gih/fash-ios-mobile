import Foundation

enum FeedPriceFormat {
    static func format(_ price: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = AppLocale.locale
        formatter.groupingSeparator = AppLocale.currentTag == AppLocale.tagEN ? "," : "."
        let n = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "₫\(n)"
    }
}
