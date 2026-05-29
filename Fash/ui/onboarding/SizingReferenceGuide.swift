import Foundation

/// Port of Android `SizingReferenceGuide` — letter sizes for profile/listing reference sizing.
enum SizingReferenceGuide {
    struct MeasurementGuide {
        let chestCm: ClosedRange<Double>
        let waistCm: ClosedRange<Double>
        let lengthCm: ClosedRange<Double>
        let shouldersCm: ClosedRange<Double>
        let sleeveCm: ClosedRange<Double>
    }

    private static let womenGuides: [String: MeasurementGuide] = [
        "XXS": MeasurementGuide(chestCm: 74...78, waistCm: 56...60, lengthCm: 58...62, shouldersCm: 34...36, sleeveCm: 56...58),
        "XS": MeasurementGuide(chestCm: 78...82, waistCm: 60...64, lengthCm: 60...64, shouldersCm: 36...38, sleeveCm: 57...59),
        "S": MeasurementGuide(chestCm: 82...86, waistCm: 64...68, lengthCm: 62...66, shouldersCm: 38...40, sleeveCm: 58...60),
        "M": MeasurementGuide(chestCm: 86...90, waistCm: 68...72, lengthCm: 64...68, shouldersCm: 40...42, sleeveCm: 59...61),
        "L": MeasurementGuide(chestCm: 90...96, waistCm: 72...78, lengthCm: 66...70, shouldersCm: 42...44, sleeveCm: 60...62),
        "XL": MeasurementGuide(chestCm: 96...102, waistCm: 78...84, lengthCm: 68...72, shouldersCm: 44...46, sleeveCm: 61...63),
        "XXL": MeasurementGuide(chestCm: 102...108, waistCm: 84...90, lengthCm: 70...74, shouldersCm: 46...48, sleeveCm: 62...64),
    ]

    private static let menGuides: [String: MeasurementGuide] = [
        "XS": MeasurementGuide(chestCm: 84...88, waistCm: 70...74, lengthCm: 66...70, shouldersCm: 40...42, sleeveCm: 59...61),
        "S": MeasurementGuide(chestCm: 88...92, waistCm: 74...78, lengthCm: 68...72, shouldersCm: 42...44, sleeveCm: 60...62),
        "M": MeasurementGuide(chestCm: 92...96, waistCm: 78...82, lengthCm: 70...74, shouldersCm: 44...46, sleeveCm: 61...63),
        "L": MeasurementGuide(chestCm: 96...100, waistCm: 82...86, lengthCm: 72...76, shouldersCm: 46...48, sleeveCm: 62...64),
        "XL": MeasurementGuide(chestCm: 100...106, waistCm: 86...92, lengthCm: 74...78, shouldersCm: 48...50, sleeveCm: 63...65),
        "XXL": MeasurementGuide(chestCm: 106...112, waistCm: 92...98, lengthCm: 76...80, shouldersCm: 50...52, sleeveCm: 64...66),
        "XXXL": MeasurementGuide(chestCm: 112...118, waistCm: 98...104, lengthCm: 78...82, shouldersCm: 52...54, sleeveCm: 65...67),
    ]

    static func sizingGuideForGender(_ genderPreference: String) -> [String: MeasurementGuide] {
        genderPreference.lowercased() == "men" ? menGuides : womenGuides
    }

    private static let womenSizeOrder = ["XXS", "XS", "S", "M", "L", "XL", "XXL"]
    private static let menSizeOrder = ["XS", "S", "M", "L", "XL", "XXL", "XXXL"]

    static func standardReferenceSizes(genderPreference: String) -> [String] {
        let order = genderPreference.lowercased() == "men" ? menSizeOrder : womenSizeOrder
        let available = Set(sizingGuideForGender(genderPreference).keys)
        return order.filter { available.contains($0) }
    }

    static func lookupSizingGuide(referenceSize: String, genderPreference: String) -> MeasurementGuide? {
        let key = referenceSize.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !key.isEmpty else { return nil }
        return sizingGuideForGender(genderPreference)[key]
    }

    static func isStandardReferenceSize(_ referenceSize: String, genderPreference: String) -> Bool {
        lookupSizingGuide(referenceSize: referenceSize, genderPreference: genderPreference) != nil
    }

    static func normalizeGenderPreference(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "men" ? "men" : "women"
    }

    static func normalizedReferenceSizeForStorage(_ raw: String, genderPreference: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if isStandardReferenceSize(trimmed, genderPreference: genderPreference) {
            return trimmed.uppercased()
        }
        return String(trimmed.prefix(40))
    }
}
