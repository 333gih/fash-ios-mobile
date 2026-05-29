import Foundation

/// Condition values shared by create and edit listing flows — Android [ListingConditionOptions].
enum ListingConditionOptions {
    static let uiValues = ["New", "Like new", "Good", "Fair", "Worn"]

    static func normalizeApiToUi(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return "" }
        let compact = t.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
        switch compact {
        case "new": return "New"
        case "like_new": return "Like new"
        case "good": return "Good"
        case "fair": return "Fair"
        case "worn": return "Worn"
        default:
            return uiValues.first { $0.caseInsensitiveCompare(t) == .orderedSame } ?? t
        }
    }

    static func normalizeUiToApi(_ ui: String) -> String {
        let t = ui.trimmingCharacters(in: .whitespaces)
        switch t {
        case "New": return "new"
        case "Like new": return "like_new"
        case "Good": return "good"
        case "Fair": return "fair"
        case "Worn": return "worn"
        default:
            return t.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
        }
    }

    static func canonicalApi(_ raw: String) -> String {
        normalizeUiToApi(normalizeApiToUi(raw))
    }
}

func conditionDefectLabel(_ key: String) -> String {
    switch key {
    case "stains": return L10n.postDefectStains
    case "worn": return L10n.postDefectWorn
    case "missing_button": return L10n.postDefectMissingButton
    case "fading": return L10n.postDefectFading
    case "pilling": return L10n.postDefectPilling
    case "odor": return L10n.postDefectOdor
    default: return key
    }
}
