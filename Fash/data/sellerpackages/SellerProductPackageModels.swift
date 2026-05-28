import Foundation

struct SellerProductPackagesResponse: Equatable {
    var packages: [SellerProductPackage]
    var serverNowUtc: String?
}

enum PackageTier: Int, Comparable {
    case starter = 0
    case growth = 1
    case premium = 2

    static func < (lhs: PackageTier, rhs: PackageTier) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct SellerProductPackage: Identifiable, Equatable {
    let id: String
    let code: String
    let name: String
    let description: String
    let priceVnd: Int64
    let durationDays: Int
    let tier: PackageTier
    let isReleased: Bool
    let isBestSeller: Bool
    let badgeLabel: String?
    let active: Bool
    let features: [SellerPackageFeature]
}

struct SellerPackageFeature: Equatable {
    let id: String
    let included: Bool
    let highlight: String?
    let name: String?
}
