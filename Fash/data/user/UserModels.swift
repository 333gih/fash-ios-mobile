import Foundation

// MARK: - User / profile DTOs (Android: data/user/UserRepository.kt model section)

struct ProfileInfo: Equatable {
    let userId: String
    let username: String
    let displayName: String
    let avatarUrl: String
    let coverImageUrl: String
    let followerCount: Int
    let followingCount: Int
    let productCount: Int
    let bio: String
    var isFollowing: Bool = false
    var aestheticTags: [String] = []
    var aestheticTagSnapshots: [AestheticTagPutItem] = []
    var referenceSize: String? = nil
    var referenceMeasurementUnit: String? = nil
    var referenceMeasurementChest: Double? = nil
    var referenceMeasurementHem: Double? = nil
    var referenceMeasurementLength: Double? = nil
    var referenceMeasurementShoulders: Double? = nil
    var referenceMeasurementSleeveLength: Double? = nil
    var gender: String = ""
    var soldCount: Int = 0
    var rating: Float? = nil
    var reviewCount: Int? = nil
    var verified: Bool = false
    var hasFastDelivery: Bool = false
    var reputationPoints: Int? = nil
    var meetingNoShowWarning: Bool = false
    var sizingReferenceCompleted: Bool = false
    var heightCm: Int? = nil
    var weightKg: Double? = nil
    var accountEmail: String = ""
    var accountPhone: String = ""
    var topBadges: [SellerBadgeSummary] = []
}

/// Core `GET …/access-status` — Android [UserAccessStatus].
struct UserAccessStatus: Equatable {
    var hasProfile: Bool
    var aestheticTagsConfigured: Bool
    var onboardingDone: Bool
    var sizingReferenceCompleted: Bool
    var shoppingPreferencesConfigured: Bool = false
    /// When present (`can_access_home`), authoritative for [canAccessHome].
    var serverCanAccessHome: Bool? = nil
    /// e.g. `password`, `onboard`, `sizing_reference`, `none`.
    var nextStep: String? = nil
    var passwordSet: Bool? = nil
    var isChangePassword: Bool? = nil
    var meetingSchedulingReverifyRequired: Bool = false
    var meetingSchedulingSuspendedUntil: String? = nil

    func needsPasswordSetup() -> Bool {
        if !onboardingDone { return false }
        if passwordSet == true { return false }
        if passwordSet == false { return true }
        if isChangePassword == true { return true }
        if nextStep?.trimmingCharacters(in: .whitespaces).lowercased() == "password" { return true }
        return false
    }

    var canAccessHome: Bool {
        if needsPasswordSetup() { return false }
        if let server = serverCanAccessHome { return server }
        if nextStep?.trimmingCharacters(in: .whitespaces).lowercased() == "none",
           hasProfile, onboardingDone, sizingReferenceCompleted, shoppingPreferencesConfigured {
            return true
        }
        return hasProfile && aestheticTagsConfigured && onboardingDone
            && sizingReferenceCompleted && shoppingPreferencesConfigured
    }
}

struct ProfilePatch: Equatable {
    var displayName: String?
    var username: String?
    var bio: String?
    var avatarUrl: String?
    var coverImageUrl: String?
    var aestheticTags: [AestheticTagPutItem]?
    var gender: String?
    var referenceSize: String?
    var referenceMeasurementUnit: String?
    var referenceMeasurementChest: Double?
    var referenceMeasurementHem: Double?
    var referenceMeasurementLength: Double?
    var referenceMeasurementShoulders: Double?
    var referenceMeasurementSleeveLength: Double?
}

struct SizingReferenceRequest: Equatable {
    var referenceSize: String
    var referenceMeasurementUnit: String
    var referenceMeasurementChest: Double = 0
    var referenceMeasurementHem: Double = 0
    var referenceMeasurementLength: Double = 0
    var referenceMeasurementShoulders: Double = 0
    var referenceMeasurementSleeveLength: Double = 0
    var heightCm: Int? = nil
    var weightKg: Double? = nil
}

struct AestheticTagPutItem: Equatable {
    let id: String
    let name: String
}

struct UserSearchResult: Identifiable, Equatable {
    var id: String { userId.isEmpty ? username : userId }
    let userId: String
    let username: String
    let displayName: String
    let avatarUrl: String
    let followerCount: Int
    let verified: Bool
    let followingCount: Int
    let listingCount: Int
}

struct FollowListPage: Equatable {
    let items: [UserSearchResult]
    let total: Int
}

struct SellerBadgeSummary: Equatable {
    let badgeId: String
    let slug: String
    let label: String
    let emoji: String
    let count: Int
}
