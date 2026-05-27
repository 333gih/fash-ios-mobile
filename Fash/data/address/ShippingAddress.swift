import Foundation

/// Saved shipping address — Android `ShippingAddress`.
struct ShippingAddress: Identifiable, Equatable, Codable {
    let id: String
    let recipientName: String
    let phone: String
    let city: String
    let district: String
    let ward: String
    let line1: String
    let isDefault: Bool
    var label: String = ""
    var line2: String = ""
    var region: String = ""
    var postalCode: String = ""
    var countryCode: String = "VN"
    var provinceId: String?
    var districtId: String?
    var wardId: String?

    func formattedAddressLine() -> String {
        dedupeConsecutiveLocality([
            line1,
            line2.isEmpty ? nil : line2,
            ward,
            district,
            city,
        ].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
            .joined(separator: ", ")
    }

    func formattedSingleLine() -> String {
        dedupeConsecutiveLocality([
            label.isEmpty ? nil : label,
            line1,
            line2.isEmpty ? nil : line2,
            ward,
            district,
            city,
        ].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
            .joined(separator: ", ")
    }

    func labelForDraft() -> String {
        let nameOrLabel = recipientName.trimmingCharacters(in: .whitespaces).isEmpty
            ? label.trimmingCharacters(in: .whitespaces)
            : recipientName.trimmingCharacters(in: .whitespaces)
        let detail = [line1, ward, district, city]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        let fallback = detail.isEmpty ? formattedSingleLine() : detail
        if !nameOrLabel.isEmpty, !fallback.isEmpty { return "\(nameOrLabel) · \(fallback)" }
        if !nameOrLabel.isEmpty { return nameOrLabel }
        if !fallback.isEmpty { return fallback }
        return formattedSingleLine()
    }

    private func dedupeConsecutiveLocality(_ parts: [String]) -> [String] {
        var out: [String] = []
        for p in parts {
            let t = p.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { continue }
            if out.last?.caseInsensitiveCompare(t) == .orderedSame { continue }
            out.append(t)
        }
        return out
    }
}
