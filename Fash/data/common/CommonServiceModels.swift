import Foundation

// MARK: - common-service DTOs (see docs/common-service-api.md)
// Field names match Go JSON (snake_case); parsers accept common variants.

struct AddressTreeNode: Identifiable, Equatable {
    var id: String
    var name: String
    var code: String
    var parentId: String?
    var level: Int
    var status: String
    var effectiveFrom: String?
    var effectiveTo: String?
    var children: [AddressTreeNode]
}

struct CommonAddressDto: Identifiable, Equatable {
    var id: String
    var name: String
    var code: String
    var parentId: String?
    var level: Int
    var status: String
    var effectiveFrom: String?
    var effectiveTo: String?
}

struct AddressHistoryPage: Equatable {
    var items: [CommonAddressDto]
    var offset: Int
    var limit: Int
}

struct CommonBrandDto: Identifiable, Equatable {
    var id: String
    var name: String
    var slug: String = ""
    var country: String = ""
    var logoUrl: String = ""
    var status: String = ""
    var createdAt: String?
    var updatedAt: String?
}

struct BrandsPage: Equatable {
    var items: [CommonBrandDto]
    var total: Int
    var offset: Int
    var limit: Int
    var hasMore: Bool
}

struct CategoryTreeNode: Identifiable, Equatable {
    var id: String
    var name: String
    var slug: String = ""
    var parentId: String?
    var sortOrder: Int = 0
    var status: String = ""
    var createdAt: String?
    var updatedAt: String?
    var children: [CategoryTreeNode]
}

struct CommonCategoryDto: Identifiable, Equatable {
    var id: String
    var name: String
    var slug: String
    var parentId: String?
    var sortOrder: Int
    var status: String
    var createdAt: String?
    var updatedAt: String?
}

struct CategoriesPage: Equatable {
    var items: [CommonCategoryDto]
    var total: Int
    var offset: Int
    var limit: Int
    var hasMore: Bool
}

struct CommonAestheticTagDto: Identifiable, Equatable {
    var id: String
    var name: String
    var displayName: String
    var displayNameVi: String = ""
    var sortOrder: Int = 0
    var status: String = ""
    var createdAt: String?
    var updatedAt: String?
}

struct AestheticTagsPage: Equatable {
    var items: [CommonAestheticTagDto]
    var total: Int
    var offset: Int
    var limit: Int
    var hasMore: Bool
}

struct CommonCountryDto: Identifiable, Equatable {
    var id: String
    var iso2: String
    var iso3: String = ""
    var name: String
    var numericCode: Int?
    var phonePrefix: String = ""
    var emoji: String = ""
    var sortOrder: Int = 0
    var status: String = ""
    var createdAt: String?
    var updatedAt: String?
}

struct CountriesPage: Equatable {
    var items: [CommonCountryDto]
    var total: Int
    var offset: Int
    var limit: Int
    var hasMore: Bool
}

/// One catalog step from `GET .../categories/{id}/listing-image-setup`.
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

/// Public catalog row from `GET .../public/safe-meetup-zones`.
struct SafeMeetupZoneDto: Identifiable, Equatable {
    var id: String
    var name: String
    var nameVi: String
    var zoneType: String
    var provinceId: String
    var districtId: String?
    var addressLine: String
    var locationUrl: String
    var sortOrder: Int

    func displayLabel(preferVi: Bool) -> String {
        let vi = nameVi.trimmingCharacters(in: .whitespacesAndNewlines)
        let en = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if preferVi, !vi.isEmpty { return vi }
        return en.isEmpty ? (vi.isEmpty ? name : vi) : en
    }
}

/// Gen Z review badge from `GET .../public/review-badges?all=true`.
struct ReviewBadgeDto: Identifiable, Equatable {
    var id: String
    var slug: String
    var nameEn: String
    var nameVi: String
    var emoji: String
    var sortOrder: Int

    func displayName(isVi: Bool) -> String {
        let vi = nameVi.trimmingCharacters(in: .whitespacesAndNewlines)
        let en = nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        if isVi, !vi.isEmpty { return vi }
        return en.isEmpty ? (vi.isEmpty ? slug : vi) : en
    }
}

func defaultListingImageCatalogSteps() -> [ListingImageStepCatalog] {
    [
        ListingImageStepCatalog(stepKey: "front", label: "Front view", labelVi: "Mặt trước", sortOrder: 0, required: true),
        ListingImageStepCatalog(stepKey: "step_2", label: "Back side", labelVi: "Mặt sau", sortOrder: 1, required: true),
    ]
}
