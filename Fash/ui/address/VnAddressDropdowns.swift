import SwiftUI

struct VnAddressDropdowns: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var addressVM: AddressBookViewModel
    @Binding var provinceId: String?
    @Binding var provinceName: String
    @Binding var districtId: String?
    @Binding var districtName: String
    @Binding var wardId: String?
    @Binding var wardName: String

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            adminMenu(
                title: L10n.addressFieldProvince,
                placeholder: L10n.addressSelectProvince,
                items: addressVM.provinces,
                selectedId: provinceId,
                onSelect: { dto in
                    provinceId = dto?.id
                    provinceName = dto?.name ?? ""
                    districtId = nil
                    districtName = ""
                    wardId = nil
                    wardName = ""
                    Task { await addressVM.onProvinceSelected(deps: deps, provinceId: dto?.id) }
                }
            )
            adminMenu(
                title: L10n.addressFieldDistrict,
                placeholder: L10n.addressSelectDistrict,
                items: addressVM.districts,
                selectedId: districtId,
                onSelect: { dto in
                    districtId = dto?.id
                    districtName = dto?.name ?? ""
                    wardId = nil
                    wardName = ""
                    Task { await addressVM.onDistrictSelected(deps: deps, districtId: dto?.id) }
                }
            )
            adminMenu(
                title: L10n.addressFieldWard,
                placeholder: L10n.addressSelectWard,
                items: addressVM.wards,
                selectedId: wardId,
                onSelect: { dto in
                    wardId = dto?.id
                    wardName = dto?.name ?? ""
                }
            )
        }
    }

    @Environment(AppDependencies.self) private var deps

    private func adminMenu(
        title: String,
        placeholder: String,
        items: [CommonAddressDto],
        selectedId: String?,
        onSelect: @escaping (CommonAddressDto?) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            Menu {
                if items.isEmpty {
                    Text(L10n.addressDropdownNoOptions)
                }
                ForEach(items, id: \.id) { item in
                    Button(item.name) { onSelect(item) }
                }
            } label: {
                HStack {
                    Text(items.first(where: { $0.id == selectedId })?.name ?? placeholder)
                        .foregroundStyle(FashColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding(12)
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}
