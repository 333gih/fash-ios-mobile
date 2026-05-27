import Foundation

/// Merges API list with local rows — Android `ShippingAddressMerge`.
func mergeShippingAddressesWithLocal(api: [ShippingAddress], local: [ShippingAddress]) -> [ShippingAddress] {
    let apiIds = Set(api.map(\.id))
    let localById = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
    let mergedFromApi = api.map { a -> ShippingAddress in
        guard let l = localById[a.id], !l.phone.trimmingCharacters(in: .whitespaces).isEmpty else { return a }
        var copy = a
        copy = ShippingAddress(
            id: a.id,
            recipientName: a.recipientName,
            phone: l.phone,
            city: a.city,
            district: a.district,
            ward: a.ward,
            line1: a.line1,
            isDefault: a.isDefault,
            label: a.label,
            line2: a.line2,
            region: a.region,
            postalCode: a.postalCode,
            countryCode: a.countryCode,
            provinceId: a.provinceId,
            districtId: a.districtId,
            wardId: a.wardId
        )
        return copy
    }
    let localOnly = local.filter { !apiIds.contains($0.id) }
    return mergedFromApi + localOnly
}
