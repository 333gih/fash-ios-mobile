import Foundation

struct ShoppingContext: Equatable {
    var source: String = "national"
    var provinceId: String = ""
    var provinceName: String = ""
    var metroKey: String = ""
    var metroLabel: String = ""
    var macroRegion: String = ""
    var climateZone: String = ""
    var seasonKey: String = ""
    var seasonLabel: String = ""
    var hasContext: Bool = false
    var suggestBrowseFromShipping: Bool = false

    func chipLabel() -> String? {
        let metro = metroLabel.trimmingCharacters(in: .whitespaces)
        let province = provinceName.trimmingCharacters(in: .whitespaces)
        let place = metro.isEmpty ? province : metro
        let season = seasonLabel.trimmingCharacters(in: .whitespaces)
        if place.isEmpty && season.isEmpty { return nil }
        if place.isEmpty { return season }
        if season.isEmpty { return place }
        return "\(place) · \(season)"
    }

    static func fromDict(_ d: [String: Any]?) -> ShoppingContext? {
        guard let d else { return nil }
        return ShoppingContext(
            source: (d["source"] as? String) ?? "national",
            provinceId: (d["province_id"] as? String) ?? (d["provinceId"] as? String) ?? "",
            provinceName: (d["province_name"] as? String) ?? (d["provinceName"] as? String) ?? "",
            metroKey: (d["metro_key"] as? String) ?? (d["metroKey"] as? String) ?? "",
            metroLabel: (d["metro_label"] as? String) ?? (d["metroLabel"] as? String) ?? "",
            macroRegion: (d["macro_region"] as? String) ?? (d["macroRegion"] as? String) ?? "",
            climateZone: (d["climate_zone"] as? String) ?? (d["climateZone"] as? String) ?? "",
            seasonKey: (d["season_key"] as? String) ?? (d["seasonKey"] as? String) ?? "",
            seasonLabel: (d["season_label"] as? String) ?? (d["seasonLabel"] as? String) ?? "",
            hasContext: (d["has_context"] as? Bool) ?? (d["hasContext"] as? Bool) ?? false,
            suggestBrowseFromShipping: (d["suggest_browse_from_shipping"] as? Bool) ?? (d["suggestBrowseFromShipping"] as? Bool) ?? false
        )
    }
}
