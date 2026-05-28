import Foundation
import Observation

@Observable
@MainActor
final class AddressBookViewModel {
    var addresses: [ShippingAddress] = []
    var loading = false
    var provincesLoading = false
    var provinces: [CommonAddressDto] = []
    var districts: [CommonAddressDto] = []
    var wards: [CommonAddressDto] = []
    var eventMessage: String?

    private func userId(from deps: AppDependencies) -> String? {
        deps.authSessionStore.read()?.userId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }

    func refresh(deps: AppDependencies) async {
        guard let uid = userId(from: deps) else { return }
        addresses = deps.addressLocalStore.listAddresses(uid)
        loading = true
        defer { loading = false }
        switch await deps.userShippingAddressRepository.listShippingAddresses() {
        case .success(let api):
            let local = deps.addressLocalStore.listAddresses(uid)
            let merged = mergeShippingAddressesWithLocal(api: api, local: local)
            deps.addressLocalStore.saveAddresses(uid, list: merged)
            addresses = merged
        case .failure:
            addresses = deps.addressLocalStore.listAddresses(uid)
            eventMessage = L10n.addressSyncFailed
        }
    }

    func clearCachesForSignedOutUser() {
        addresses = []
        loading = false
        provinces = []
        districts = []
        wards = []
    }

    func loadProvincesIfNeeded(deps: AppDependencies) async {
        guard provinces.isEmpty else { return }
        provincesLoading = true
        defer { provincesLoading = false }
        switch await deps.commonCatalogRepository.getProvincesCatalog() {
        case .success(let list): provinces = list
        case .failure: eventMessage = L10n.addressCatalogLoadFailed
        }
    }

    func onProvinceSelected(deps: AppDependencies, provinceId: String?) async {
        guard let provinceId, !provinceId.isEmpty else {
            districts = []
            wards = []
            return
        }
        switch await deps.commonCatalogRepository.getAdministrativeChildren(parentId: provinceId, childLevel: 2) {
        case .success(let list): districts = list
        case .failure:
            districts = []
            eventMessage = L10n.addressCatalogLoadFailed
        }
        wards = []
    }

    func onDistrictSelected(deps: AppDependencies, districtId: String?) async {
        guard let districtId, !districtId.isEmpty else {
            wards = []
            return
        }
        switch await deps.commonCatalogRepository.getAdministrativeChildren(parentId: districtId, childLevel: 3) {
        case .success(let list): wards = list
        case .failure:
            wards = []
            eventMessage = L10n.addressCatalogLoadFailed
        }
    }

    func resetAdministrativeDropdowns() {
        districts = []
        wards = []
    }

    func addressById(_ id: String) -> ShippingAddress? {
        addresses.first { $0.id == id }
    }

    func setDefaultAddress(deps: AppDependencies, addressId: String) async {
        guard let uid = userId(from: deps) else { return }
        switch await deps.userShippingAddressRepository.setDefaultShippingAddress(addressId: addressId) {
        case .success:
            if case .success(let api) = await deps.userShippingAddressRepository.listShippingAddresses() {
                let local = deps.addressLocalStore.listAddresses(uid)
                let merged = mergeShippingAddressesWithLocal(api: api, local: local)
                deps.addressLocalStore.saveAddresses(uid, list: merged)
                addresses = merged
            }
        case .failure(let err):
            eventMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    func createShippingAddress(
        deps: AppDependencies,
        label: String,
        recipientName: String,
        phone: String,
        line1: String,
        line2: String,
        city: String,
        region: String,
        postalCode: String,
        countryCode: String,
        provinceId: String?,
        provinceName: String,
        districtId: String?,
        districtName: String,
        wardId: String?,
        wardName: String,
        isDefault: Bool
    ) async -> Result<String, Error> {
        guard let uid = userId(from: deps) else {
            return .failure(NSError(domain: "AddressBook", code: 0, userInfo: [NSLocalizedDescriptionKey: "not signed in"]))
        }
        let list = deps.addressLocalStore.listAddresses(uid)
        let mustDefault = list.isEmpty
        let req = CreateUserShippingAddressRequest(
            line1: line1.trimmingCharacters(in: .whitespaces),
            countryCode: String(countryCode.trimmingCharacters(in: .whitespaces).uppercased().prefix(2)).isEmpty ? "VN" : String(countryCode.trimmingCharacters(in: .whitespaces).uppercased().prefix(2)),
            label: label.trimmingCharacters(in: .whitespaces),
            recipientName: recipientName.trimmingCharacters(in: .whitespaces),
            line2: line2.trimmingCharacters(in: .whitespaces),
            city: city.trimmingCharacters(in: .whitespaces),
            region: region.trimmingCharacters(in: .whitespaces),
            postalCode: postalCode.trimmingCharacters(in: .whitespaces),
            isDefault: isDefault || mustDefault,
            provinceId: provinceId?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            provinceName: provinceName.trimmingCharacters(in: .whitespaces),
            districtId: districtId?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            districtName: districtName.trimmingCharacters(in: .whitespaces),
            wardId: wardId?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            wardName: wardName.trimmingCharacters(in: .whitespaces)
        )
        switch await deps.userShippingAddressRepository.createShippingAddress(req) {
        case .success(let created):
            var withPhone = created
            withPhone = ShippingAddress(
                id: created.id, recipientName: created.recipientName, phone: phone.trimmingCharacters(in: .whitespaces),
                city: created.city, district: created.district, ward: created.ward, line1: created.line1,
                isDefault: created.isDefault, label: created.label, line2: created.line2, region: created.region,
                postalCode: created.postalCode, countryCode: created.countryCode,
                provinceId: created.provinceId, districtId: created.districtId, wardId: created.wardId
            )
            _ = deps.addressLocalStore.upsertAddress(uid, address: withPhone)
            addresses = deps.addressLocalStore.listAddresses(uid)
            eventMessage = L10n.addressSavedSuccess
            return .success(withPhone.id)
        case .failure(let err):
            return .failure(err)
        }
    }

    func initialSelectionIdForOrder(deps: AppDependencies, orderId: String) -> String? {
        guard let uid = userId(from: deps) else { return nil }
        let oid = orderId.trimmingCharacters(in: .whitespaces).lowercased()
        if let mapped = deps.addressLocalStore.getOrderAddressId(uid, orderId: oid) { return mapped }
        let list = deps.addressLocalStore.listAddresses(uid)
        return list.first(where: \.isDefault)?.id ?? list.first?.id
    }

    func setOrderShipping(deps: AppDependencies, orderId: String, address: ShippingAddress) async {
        guard let uid = userId(from: deps) else { return }
        deps.addressLocalStore.setOrderAddressId(uid, orderId: orderId, addressId: address.id)
        await refresh(deps: deps)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
