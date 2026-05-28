import Foundation

/// Resolves bilingual catalog/API labels based on in-app locale (vi default, en optional).
enum BilingualLabel {
    static func resolve(en: String, vi: String) -> String {
        let preferVi = AppLocale.currentTag != AppLocale.tagEN
        let viTrim = vi.trimmingCharacters(in: .whitespacesAndNewlines)
        let enTrim = en.trimmingCharacters(in: .whitespacesAndNewlines)
        if preferVi, !viTrim.isEmpty { return viTrim }
        return enTrim.isEmpty ? (viTrim.isEmpty ? en : viTrim) : enTrim
    }
}
