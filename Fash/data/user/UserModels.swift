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

/// Onboarding / home gate flags from `GET .../setup-status`.
struct UserAccessStatus: Equatable {
    var needsUsername: Bool
    var needsPassword: Bool
    var needsProfilePhoto: Bool
    var needsShoppingPrefs: Bool
    var needsSizing: Bool
    var needsAestheticTags: Bool
    var canAccessHome: Bool
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
    var measurementUnit: String?
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var height: Double?
    var weight: Double?
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
