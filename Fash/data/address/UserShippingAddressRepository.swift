import Foundation

struct CreateUserShippingAddressRequest {
    let line1: String
    let countryCode: String
    var label: String = ""
    var recipientName: String = ""
    var line2: String = ""
    var city: String = ""
    var region: String = ""
    var postalCode: String = ""
    var isDefault: Bool = false
    var provinceId: String?
    var provinceName: String = ""
    var districtId: String?
    var districtName: String = ""
    var wardId: String?
    var wardName: String = ""

    func toJSON() -> [String: Any] {
        var o: [String: Any] = [
            "line1": line1,
            "country_code": countryCode,
            "is_default": isDefault,
        ]
        if !label.isEmpty { o["label"] = label }
        if !recipientName.isEmpty { o["recipient_name"] = recipientName }
        if !line2.isEmpty { o["line2"] = line2 }
        if !city.isEmpty { o["city"] = city }
        if !region.isEmpty { o["region"] = region }
        if !postalCode.isEmpty { o["postal_code"] = postalCode }
        if let provinceId, !provinceId.isEmpty { o["province_id"] = provinceId }
        if !provinceName.isEmpty { o["province_name"] = provinceName }
        if let districtId, !districtId.isEmpty { o["district_id"] = districtId }
        if !districtName.isEmpty { o["district_name"] = districtName }
        if let wardId, !wardId.isEmpty { o["ward_id"] = wardId }
        if !wardName.isEmpty { o["ward_name"] = wardName }
        return o
    }
}

/// Core-service user shipping addresses — Android `UserShippingAddressRepository`.
final class UserShippingAddressRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) { self.client = client }

    private var listURL: String {
        AppEnvironment.apiPath("api/v1/users/me/shipping-addresses")
    }

    func listShippingAddresses() async -> Result<[ShippingAddress], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/users/me/shipping-addresses",
                client: client
            )
            return .success(ShippingAddressParsing.parseList(data))
        } catch {
            return .failure(error)
        }
    }

    func createShippingAddress(_ request: CreateUserShippingAddressRequest) async -> Result<ShippingAddress, Error> {
        guard let url = URL(string: listURL) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: request.toJSON())
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(
                    statusCode: http.statusCode,
                    message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                )
            }
            let obj = try RepositoryHttp.jsonObject(data)
            let payload = (obj["data"] as? [String: Any]) ?? obj
            return .success(ShippingAddressParsing.parse(payload))
        } catch {
            return .failure(error)
        }
    }

    func setDefaultShippingAddress(addressId: String) async -> Result<Void, Error> {
        let path = "api/v1/users/me/shipping-addresses/\(addressId.trimmingCharacters(in: .whitespaces))/default"
        guard let url = URL(string: AppEnvironment.apiPath(path)) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)
        do {
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(
                    statusCode: http.statusCode,
                    message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                )
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
