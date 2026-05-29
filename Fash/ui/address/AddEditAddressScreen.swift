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
    @State private var validationError = false
    @State private var saveError: String?

    var body: some View {
        OverlayScreenHost(title: L10n.addressAddTitle, onDismiss: onDismiss) {
            Group {
                if addressVM.provincesLoading && addressVM.provinces.isEmpty {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    formContent
                }
            }
        }
        .task {
            await addressVM.loadProvincesIfNeeded(deps: deps)
            addressVM.resetAdministrativeDropdowns()
        }
        .onChange(of: selectedProvince?.id) { _, newId in
            Task {
                await addressVM.onProvinceSelected(deps: deps, provinceId: newId)
                if newId == nil {
                    selectedDistrict = nil
                    selectedWard = nil
                }
            }
        }
        .onChange(of: selectedDistrict?.id) { _, newId in
            Task {
                await addressVM.onDistrictSelected(deps: deps, districtId: newId)
                if newId == nil {
                    selectedWard = nil
                }
            }
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing4) {
                Text(L10n.addressSectionShipping)
                    .font(FashTypography.labelSmall.weight(.bold))
                    .foregroundStyle(FashColors.brandPrimary)
                Text(L10n.addressFormHeader)
                    .font(FashTypography.headlineSmall.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                if showCatalogHint {
                    Text(L10n.addressVnCatalogHint)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                if let catalogErr = addressVM.eventMessage, !catalogErr.isEmpty {
                    Text(catalogErr)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.error)
                }
                AddressFormField(
                    label: L10n.addressFieldLabelOptional,
                    text: $label,
                    placeholder: L10n.addressFieldLabelHint
                )
                AddressFormField(
                    label: L10n.addressFieldFullName,
                    text: $recipientName,
                    placeholder: L10n.addressFieldFullNameHint
                )
                AddressFormField(
                    label: L10n.addressFieldPhone,
                    text: $phone,
                    placeholder: L10n.addressFieldPhoneHint
                )
                countryField
                VnAddressDropdowns(
                    addressVM: addressVM,
                    selectedProvince: $selectedProvince,
                    selectedDistrict: $selectedDistrict,
                    selectedWard: $selectedWard
                )
                AddressFormField(
                    label: L10n.addressFieldLine1,
                    text: $line1,
                    placeholder: L10n.addressFieldLine1Hint,
                    multiline: true
                )
                AddressFormField(
                    label: L10n.addressFieldLine2Optional,
                    text: $line2,
                    placeholder: L10n.addressFieldLine2Hint
                )
                AddressFormField(
                    label: L10n.addressFieldPostalOptional,
                    text: Binding(
                        get: { postalCode },
                        set: { postalCode = String($0.filter(\.isNumber).prefix(12)) }
                    ),
                    placeholder: L10n.addressFieldPostalHint
                )
                if validationError {
                    Text(L10n.addressValidationRequired)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.error)
                }
                if let saveError, !saveError.isEmpty {
                    Text(saveError)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.error)
                }
                defaultToggle
                saveButton
            }
            .padding(spacing.spacing4)
        }
    }

    private var countryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.addressCountryFixed)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
            TextField("", text: .constant(L10n.addressCountryVn))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
        }
    }

    private var defaultToggle: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.addressDefaultToggle)
                    .font(FashTypography.titleSmall.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                Text(L10n.addressDefaultToggleSub)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isDefault)
                .labelsHidden()
                .disabled(isSaving)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(FashGradients.primaryCta(in: CGSize(width: 320, height: 48)))
                if isSaving {
                    ProgressView().tint(FashColors.readableOnBrandPrimary)
                } else {
                    HStack(spacing: 8) {
                        Text(L10n.addressSave)
                            .font(FashTypography.labelLarge.weight(.bold))
                            .foregroundStyle(FashColors.readableOnBrandPrimary)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(FashColors.readableOnBrandPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .disabled(isSaving)
        .buttonStyle(.plain)
        .padding(.top, spacing.spacing2)
    }

    private func save() async {
        let hasArea = selectedProvince != nil && selectedDistrict != nil && selectedWard != nil
        let ok = !recipientName.trimmingCharacters(in: .whitespaces).isEmpty
            && !phone.trimmingCharacters(in: .whitespaces).isEmpty
            && !line1.trimmingCharacters(in: .whitespaces).isEmpty
            && hasArea
        guard ok else {
            validationError = true
            saveError = nil
            return
        }
        validationError = false
        saveError = nil
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
            saveError = FashErrorPresentation.userMessage(for: err)
            validationError = false
        }
    }
}

private struct AddressFormField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var multiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
            if multiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
