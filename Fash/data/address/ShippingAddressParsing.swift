import Foundation

/// Parses core-service shipping address JSON — Android `ShippingAddressParsing`.
enum ShippingAddressParsing {
    static func parse(_ o: [String: Any]) -> ShippingAddress {
        func s(_ keys: String...) -> String {
            for k in keys {
                if let v = o[k] as? String, !v.isEmpty { return v }
            }
            return ""
        }
        let provinceName = s("province_name", "ProvinceName", "provinceName")
        let districtName = s("district_name", "DistrictName", "districtName")
        let wardName = s("ward_name", "WardName", "wardName")
        let cityRaw = s("city", "City").isEmpty ? provinceName : s("city", "City")
        let districtRaw = districtName.isEmpty ? s("district", "District") : districtName
        let wardRaw = wardName.isEmpty ? s("ward", "Ward") : wardName
        let isDefault: Bool = {
            if let b = o["IsDefault"] as? Bool { return b }
            if let b = o["is_default"] as? Bool { return b }
            if let b = o["isDefault"] as? Bool { return b }
            if let n = o["is_default"] as? NSNumber { return n.boolValue }
            return false
        }()
        let id = s("id", "ID", "Uuid", "uuid")
        return ShippingAddress(
            id: id.isEmpty ? UUID().uuidString : id,
            recipientName: s("recipient_name", "RecipientName", "recipientName"),
            phone: s("phone", "Phone", "mobile", "Mobile", "recipient_phone", "RecipientPhone"),
            city: cityRaw,
            district: districtRaw,
            ward: wardRaw,
            line1: s("line1", "Line1", "line_1", "address_line1", "AddressLine1", "street", "Street"),
            isDefault: isDefault,
            label: s("label", "Label"),
            line2: s("line2", "Line2", "line_2"),
            region: s("region", "Region"),
            postalCode: s("postal_code", "PostalCode", "postalCode"),
            countryCode: s("country_code", "CountryCode", "country").isEmpty ? "VN" : s("country_code", "CountryCode", "country"),
            provinceId: s("province_id", "ProvinceID", "provinceId").nilIfEmpty,
            districtId: s("district_id", "DistrictID", "districtId").nilIfEmpty,
            wardId: s("ward_id", "WardID", "wardId").nilIfEmpty
        )
    }

    static func parseList(_ data: Data) -> [ShippingAddress] {
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return [] }
        if let arr = root as? [[String: Any]] {
            return arr.map { parse($0) }
        }
        if let obj = root as? [String: Any] {
            if let arr = obj["data"] as? [[String: Any]] { return arr.map { parse($0) } }
            if let arr = obj["addresses"] as? [[String: Any]] { return arr.map { parse($0) } }
        }
        return []
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
