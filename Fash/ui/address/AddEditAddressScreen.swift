import SwiftUI

struct AddEditAddressScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var addressVM: AddressBookViewModel
    var showCatalogHint: Bool = true
    var onDismiss: () -> Void = {}
    var onSaved: (String?) -> Void = { _ in }

    @State private var label = ""
    @State private var recipientName = ""
    @State private var phone = ""
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var postalCode = ""
    @State private var isDefault = false
    @State private var selectedProvince: CommonAddressDto?
    @State private var selectedDistrict: CommonAddressDto?
    @State private var selectedWard: CommonAddressDto?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        OverlayScreenHost(title: L10n.addressAddTitle, onDismiss: onDismiss) {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.spacing4) {
                    if showCatalogHint {
                        Text(L10n.addressVnCatalogHint)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    field(L10n.addressFieldLabelOptional, text: $label, hint: L10n.addressFieldLabelHint)
                    field(L10n.addressFieldFullName, text: $recipientName, hint: L10n.addressFieldFullNameHint)
                    field(L10n.addressFieldPhone, text: $phone, hint: L10n.addressFieldPhoneHint)
                    field(L10n.addressCountryFixed, text: .constant(L10n.addressCountryVn), hint: "")
                        .disabled(true)
                        .opacity(0.75)
                    field(L10n.addressFieldLine1, text: $line1, hint: L10n.addressFieldLine1Hint)
                    field(L10n.addressFieldLine2Optional, text: $line2, hint: L10n.addressFieldLine2Hint)
                    field(
                        L10n.addressFieldPostalOptional,
                        text: Binding(
                            get: { postalCode },
                            set: { postalCode = String($0.filter(\.isNumber).prefix(12)) }
                        ),
                        hint: L10n.addressFieldPostalHint
                    )
                    VnAddressDropdowns(
                        addressVM: addressVM,
                        selectedProvince: $selectedProvince,
                        selectedDistrict: $selectedDistrict,
                        selectedWard: $selectedWard
                    )
                    Toggle(L10n.addressDefaultToggle, isOn: $isDefault)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.error)
                    }
                    FashPrimaryButton(title: L10n.addressSave, isLoading: isSaving) {
                        Task { await save() }
                    }
                }
                .padding(spacing.spacing4)
            }
        }
        .task {
            await addressVM.loadProvincesIfNeeded(deps: deps)
            addressVM.resetAdministrativeDropdowns()
        }
    }

    private func field(_ title: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            TextField(hint, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func save() async {
        guard validate() else { return }
        isSaving = true
        defer { isSaving = false }
        let result = await addressVM.createShippingAddress(
            deps: deps,
            label: label,
            recipientName: recipientName,
            phone: phone,
            line1: line1,
            line2: line2,
            city: selectedProvince?.name ?? "",
            region: selectedDistrict?.name ?? "",
            postalCode: postalCode,
            countryCode: "VN",
            provinceId: selectedProvince?.id,
            provinceName: selectedProvince?.name ?? "",
            districtId: selectedDistrict?.id,
            districtName: selectedDistrict?.name ?? "",
            wardId: selectedWard?.id,
            wardName: selectedWard?.name ?? "",
            isDefault: isDefault
        )
        switch result {
        case .success(let id):
            onSaved(id)
            onDismiss()
        case .failure(let err):
            errorMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    private func validate() -> Bool {
        guard !recipientName.trimmingCharacters(in: .whitespaces).isEmpty,
              !phone.trimmingCharacters(in: .whitespaces).isEmpty,
              !line1.trimmingCharacters(in: .whitespaces).isEmpty,
              selectedProvince != nil,
              selectedDistrict != nil,
              selectedWard != nil else {
            errorMessage = L10n.addressValidationRequired
            return false
        }
        errorMessage = nil
        return true
    }
}
