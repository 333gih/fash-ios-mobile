import Foundation

struct SellerListingFocus: Equatable {
    let categories: [SellerFocusCategory]
    let brands: [SellerFocusBrand]
    let aestheticTags: [SellerFocusTag]

    var isEmpty: Bool {
        categories.isEmpty && brands.isEmpty && aestheticTags.isEmpty
    }
}

struct SellerFocusCategory: Equatable, Identifiable {
    var id: String
    let name: String
    let parentId: String?
    let parentName: String?

    func displayLabel() -> String {
        let p = parentName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p.isEmpty, !n.isEmpty { return "\(p) · \(n)" }
        return n.isEmpty ? "—" : n
    }
}

struct SellerFocusBrand: Equatable, Identifiable {
    var id: String
    let name: String
}

struct SellerFocusTag: Equatable, Identifiable {
    var id: String
    let name: String
}

enum SellerFocusError: Error, Equatable {
    case forbidden
    case unauthorized
}
