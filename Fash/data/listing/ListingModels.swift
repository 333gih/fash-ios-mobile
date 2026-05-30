import Foundation

// MARK: - Listing wire models (Android: data/listing/ListingModels.kt + ListingRepository request types)

struct ListingShippingAddress: Equatable {
    var label: String?
    var line1: String
    var line2: String?
    var city: String?
    var region: String?
    var postalCode: String?
    var countryCode: String?
}

struct AestheticTagRef: Equatable {
    var id: String?
    var label: String
}

/// Full listing detail for product detail screen (`GET /listings/:id`).
struct ListingDetail: Equatable {
    var id: String
    var title: String
    var description: String
    var imageUrls: [String]
    var priceVnd: Int64
    var listPriceVnd: Int64?
    var condition: String
    var category: String?
    var categoryId: String?
    var parentCategoryName: String?
    var parentCategoryId: String?
    var size: String?
    var brand: String?
    var brandId: String?
    var material: String?
    var tags: [String]
    var likeCount: Int
    var saveCount: Int
    var viewCount: Int
    var measurementUnit: String?
    var measurementHem: Double?
    var measurementChest: Double?
    var measurementLength: Double?
    var measurementShoulders: Double?
    var measurementSleeveLength: Double?
    var aestheticTags: [String]
    var aestheticTagRefs: [AestheticTagRef]
    var acceptOffers: Bool
    var autoPriceDropEnabled: Bool
    var floorPriceVnd: Int64?
    var priceDropPercent: Int?
    var nextPriceDropAtIso: String?
    var countryName: String?
    var countryId: String?
    var countryIso2: String?
    var shippingAddress: ListingShippingAddress?
    var estimatedShippingVnd: Int64?
    var sellerId: String?
    var sellerUsername: String?
    var sellerAvatarUrl: String?
    var sellerDisplayName: String?
    var sellerVerified: Bool
    var sellerListingCount: Int?
    var sellerFollowerCount: Int?
    var sellerFollowingCount: Int?
    var sellerAverageRating: Float?
    var createdAtIso: String?
    var updatedAtIso: String?
    var isLiked: Bool
    var isSaved: Bool
    var sellerIsFollowing: Bool?
    var status: String
    var color: String?
    var genderTarget: String?
}

struct NamedRefPayload: Equatable {
    let id: String
    let name: String
}

struct ListingImageStepPayload: Equatable {
    let stepKey: String
    let label: String
    let labelVi: String?
    let sortOrder: Int
    let required: Bool
    let imageUrl: String
    let width: Int?
    let height: Int?
}

struct CreateListingRequest: Equatable {
    let title: String
    let imageUrlSteps: [ListingImageStepPayload]
    let priceVnd: Int64
    let condition: String
    let category: NamedRefPayload
    var description: String = ""
    var size: String = ""
    var color: String?
    var genderTarget: String?
    var parentCategory: NamedRefPayload?
    var brand: NamedRefPayload?
    var aestheticTags: [NamedRefPayload] = []
    var countryOfOrigin: String?
    var countryId: String?
    var countryName: String?
    var measurementUnit: String?
    var measurementHem: Double?
    var measurementChest: Double?
    var measurementLength: Double?
    var measurementShoulders: Double?
    var measurementSleeveLength: Double?
    var acceptOffers: Bool?
    var autoPriceDropEnabled: Bool?
    var floorPriceVnd: Int64?
    var priceDropPercent: Int?
    var shippingAddressId: String?
    var onsiteInspectionCommitment: Bool?
    var conditionScore: Int?
    var conditionDefects: [String] = []
}

struct CreateListingResponse: Equatable {
    let id: String
}

struct UpdateListingRequest: Equatable {
    var title: String?
    var description: String?
    var priceVnd: Int64?
    var condition: String?
    var size: String?
    var status: String?
}
