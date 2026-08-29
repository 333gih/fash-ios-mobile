import Foundation

struct UserEntitlementSummary: Equatable {
    var packageId: String = ""
    var packageCode: String = ""
    var packageName: String = ""
    var features: [String: FeatureUsageSummary] = [:]
}

struct FeatureUsageSummary: Equatable {
    var enabled: Bool = false
    var featureGroup: String = ""
    var executionKind: String = ""
    var name: String = ""
    var description: String = ""
    var requiresListing: Bool = false
    var fulfillmentMode: String = ""
    var verificationKind: String = ""
    var disclaimerText: String = ""
    var latestRequestStatus: String = ""
    var latestResultVerdict: String = ""
    var latestConfidencePct: Int?
    var boostAffinityHint: String = ""
    var used: Int64 = 0
    var remaining: Int64?
    var unlimited: Bool = false
    var durationDays: Int = 0
    var priority: Bool = false
}

struct PackageActivationResult: Equatable {
    var packageCode: String = ""
    var packageName: String = ""
    var entitlements: UserEntitlementSummary?
}
