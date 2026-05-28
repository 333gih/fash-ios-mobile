import SwiftUI

struct VnAddressDropdowns: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var addressVM: AddressBookViewModel
    @Binding var selectedProvince: CommonAddressDto?
    @Binding var selectedDistrict: CommonAddressDto?
    @Binding var selectedWard: CommonAddressDto?

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            adminMenu(
                title: L10n.addressFieldProvince,
                placeholder: L10n.addressSelectProvince,
                items: addressVM.provinces,
                selectedId: selectedProvince?.id,
                onSelect: { dto in
                    selectedProvince = dto
                    selectedDistrict = nil
                    selectedWard = nil
                    Task { await addressVM.onProvinceSelected(deps: deps, provinceId: dto?.id) }
                }
            )
            adminMenu(
                title: L10n.addressFieldDistrict,
                placeholder: L10n.addressSelectDistrict,
                items: addressVM.districts,
                selectedId: selectedDistrict?.id,
                isEnabled: selectedProvince != nil,
                onSelect: { dto in
                    selectedDistrict = dto
                    selectedWard = nil
                    Task { await addressVM.onDistrictSelected(deps: deps, districtId: dto?.id) }
                }
            )
            adminMenu(
                title: L10n.addressFieldWard,
                placeholder: L10n.addressSelectWard,
                items: addressVM.wards,
                selectedId: selectedWard?.id,
                isEnabled: selectedDistrict != nil,
                onSelect: { dto in
                    selectedWard = dto
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
        isEnabled: Bool = true,
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
                        .foregroundStyle(isEnabled ? FashColors.textPrimary : FashColors.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding(12)
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .disabled(!isEnabled)
        }
    }
}
