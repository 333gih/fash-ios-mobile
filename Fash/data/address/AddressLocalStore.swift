import Foundation

/// Persists shipping addresses per logged-in user — Android `AddressLocalStore`.
final class AddressLocalStore {
    private let prefs = UserDefaults.standard
    private let prefsName = "fash_shipping_addresses"

    private func keyAddresses(_ userId: String) -> String {
        "addr_list_\(userId.trimmingCharacters(in: .whitespaces))"
    }

    private func keyOrderMap(_ userId: String) -> String {
        "addr_order_map_\(userId.trimmingCharacters(in: .whitespaces))"
    }

    func listAddresses(_ userId: String) -> [ShippingAddress] {
        guard let raw = prefs.string(forKey: keyAddresses(userId)) else { return [] }
        guard let data = raw.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([ShippingAddress].self, from: data)) ?? []
    }

    func saveAddresses(_ userId: String, list: [ShippingAddress]) {
        guard let data = try? JSONEncoder().encode(list),
              let raw = String(data: data, encoding: .utf8) else { return }
        prefs.set(raw, forKey: keyAddresses(userId))
    }

    func upsertAddress(_ userId: String, address: ShippingAddress) -> [ShippingAddress] {
        var current = listAddresses(userId)
        if let idx = current.firstIndex(where: { $0.id == address.id }) {
            current[idx] = address
        } else {
            current.append(address)
        }
        let normalized: [ShippingAddress]
        if address.isDefault {
            normalized = current.map { a in
                var copy = a
                if a.id != address.id {
                    copy = ShippingAddress(
                        id: a.id, recipientName: a.recipientName, phone: a.phone,
                        city: a.city, district: a.district, ward: a.ward, line1: a.line1,
                        isDefault: false, label: a.label, line2: a.line2, region: a.region,
                        postalCode: a.postalCode, countryCode: a.countryCode,
                        provinceId: a.provinceId, districtId: a.districtId, wardId: a.wardId
                    )
                }
                return copy
            }
        } else {
            normalized = current
        }
        saveAddresses(userId, list: normalized)
        return normalized
    }

    func getDefaultOrFirst(_ userId: String) -> ShippingAddress? {
        let list = listAddresses(userId)
        return list.first(where: \.isDefault) ?? list.first
    }

    func getOrderAddressId(_ userId: String, orderId: String) -> String? {
        let map = loadOrderMap(userId)
        return map[orderId.trimmingCharacters(in: .whitespaces).lowercased()]
    }

    func setOrderAddressId(_ userId: String, orderId: String, addressId: String) {
        var map = loadOrderMap(userId)
        map[orderId.trimmingCharacters(in: .whitespaces).lowercased()] = addressId
        saveOrderMap(userId, map: map)
    }

    private func loadOrderMap(_ userId: String) -> [String: String] {
        guard let raw = prefs.string(forKey: keyOrderMap(userId)),
              let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return obj.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func saveOrderMap(_ userId: String, map: [String: String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: map),
              let raw = String(data: data, encoding: .utf8) else { return }
        prefs.set(raw, forKey: keyOrderMap(userId))
    }

    // Legacy API used by older code paths
    func loadJSON() -> Data? { nil }
    func saveJSON(_ data: Data) { _ = data }
}
