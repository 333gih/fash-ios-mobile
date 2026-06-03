import Foundation

/// Wear metadata for seasonal recommendations — mirrors `docs/listing-wear-season.md`.
enum ListingWearSeason {
    struct Option: Identifiable, Hashable {
        let id: String
        let labelVi: String
        let labelEn: String

        var idValue: String { id }

        func label(localeVi: Bool) -> String { localeVi ? labelVi : labelEn }
    }

    static let seasonOptions: [Option] = [
        Option(id: "dry_hot", labelVi: "Mùa khô nóng", labelEn: "Dry hot season"),
        Option(id: "rainy", labelVi: "Mùa mưa", labelEn: "Rainy season"),
        Option(id: "cold_dry", labelVi: "Mùa lạnh khô", labelEn: "Cool dry season"),
        Option(id: "hot_humid", labelVi: "Mùa nóng ẩm", labelEn: "Hot humid season"),
        Option(id: "mild", labelVi: "Mùa dịu", labelEn: "Mild season"),
        Option(id: "dry", labelVi: "Mùa khô", labelEn: "Dry season"),
        Option(id: "cool_dry", labelVi: "Mùa se lạnh", labelEn: "Cool dry season"),
        Option(id: "warm_rain", labelVi: "Mùa mưa ấm", labelEn: "Warm rainy season"),
    ]

    static let climateZoneOptions: [Option] = [
        Option(id: "south_tropical", labelVi: "Nam Bộ nhiệt đới", labelEn: "South tropical"),
        Option(id: "north_subtropical", labelVi: "Bắc Bộ cận nhiệt", labelEn: "North subtropical"),
        Option(id: "central_rainy", labelVi: "Miền Trung mưa nhiều", labelEn: "Central rainy"),
        Option(id: "highland_cool", labelVi: "Tây Nguyên mát", labelEn: "Highland cool"),
    ]

    static let macroRegionOptions: [Option] = [
        Option(id: "south", labelVi: "Miền Nam", labelEn: "South"),
        Option(id: "north", labelVi: "Miền Bắc", labelEn: "North"),
        Option(id: "central", labelVi: "Miền Trung", labelEn: "Central"),
        Option(id: "highland", labelVi: "Tây Nguyên", labelEn: "Highland"),
    ]

    static func labelForSeasonKey(_ key: String, localeVi: Bool) -> String {
        let k = key.trimmingCharacters(in: .whitespaces).lowercased()
        return seasonOptions.first { $0.id == k }?.label(localeVi: localeVi) ?? k
    }

    static func summary(
        seasonKeys: [String],
        climateZones: [String],
        macroRegions: [String],
        yearRoundWear: Bool,
        localeVi: Bool
    ) -> String? {
        var parts: [String] = []
        if yearRoundWear {
            parts.append(localeVi ? "Mặc quanh năm" : "Year-round wear")
        }
        let seasons = seasonKeys.map { labelForSeasonKey($0, localeVi: localeVi) }.filter { !$0.isEmpty }
        if !seasons.isEmpty {
            parts.append(seasons.joined(separator: ", "))
        }
        let zones = climateZones.compactMap { z in climateZoneOptions.first { $0.id == z }?.label(localeVi: localeVi) }
        if !zones.isEmpty {
            parts.append(zones.joined(separator: ", "))
        }
        let regions = macroRegions.compactMap { r in macroRegionOptions.first { $0.id == r }?.label(localeVi: localeVi) }
        if !regions.isEmpty {
            parts.append(regions.joined(separator: ", "))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
