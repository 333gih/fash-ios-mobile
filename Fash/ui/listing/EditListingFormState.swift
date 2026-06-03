import Foundation

/// Editable fields for edit listing — Android `EditListingFormState`.
struct EditListingFormState: Equatable {
    var title: String = ""
    var description: String = ""
    var priceText: String = ""
    var condition: String = ""
    var size: String = ""
    var brandId: String?
    var brandName: String = ""
    var selectedTagIds: Set<String> = []
    var countryId: String?
    var countryIso2: String = ""
    var countryName: String = ""
    var measurementUnit: String = "cm"
    var measurementHem: String = ""
    var measurementChest: String = ""
    var measurementLength: String = ""
    var measurementShoulders: String = ""
    var measurementSleeveLength: String = ""
    var acceptOffers: Bool = false
    var autoPriceDropEnabled: Bool = false
    var floorPriceText: String = ""
    var priceDropPercentInput: String = "10"
    var color: String = ""
    var genderTarget: String = ""
    var seasonKeys: Set<String> = []
    var climateZones: Set<String> = []
    var macroRegions: Set<String> = []
    var yearRoundWear: Bool = false
}
