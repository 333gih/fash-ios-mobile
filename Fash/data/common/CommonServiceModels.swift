import Foundation

struct CommonAddressDto: Identifiable, Equatable {
    var id: String
    var name: String
    var code: String = ""
    var parentId: String = ""
    var level: Int = 0
}

struct CategoryTreeNode: Identifiable, Equatable {
    var id: String
    var name: String
    var children: [CategoryTreeNode] = []
}

struct CommonAestheticTagDto: Identifiable, Equatable {
    var id: String
    var name: String
    var displayName: String
    var displayNameVi: String = ""
}

struct CommonBrandDto: Identifiable, Equatable {
    var id: String
    var name: String
}

struct BrandsPage: Equatable {
    var items: [CommonBrandDto]
    var total: Int
}

struct CommonCountryDto: Identifiable, Equatable {
    var id: String
    var name: String
    var iso2: String
}

struct ListingImageStepCatalog: Equatable {
    var stepKey: String
    var label: String
    var labelVi: String
    var sortOrder: Int
    var required: Bool
}

struct ListingImageSetupDto: Equatable {
    var categoryId: String
    var steps: [ListingImageStepCatalog]
}

func defaultListingImageCatalogSteps() -> [ListingImageStepCatalog] {
    [
        ListingImageStepCatalog(stepKey: "front", label: "Front view", labelVi: "Mặt trước", sortOrder: 0, required: true),
        ListingImageStepCatalog(stepKey: "step_2", label: "Back side", labelVi: "Mặt sau", sortOrder: 1, required: true),
    ]
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
