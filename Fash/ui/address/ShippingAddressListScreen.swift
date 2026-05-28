import SwiftUI

struct ShippingAddressListScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var addressVM: AddressBookViewModel
    var orderId: String?
    var onDismiss: () -> Void = {}
    var onAddAddress: (() -> Void)?

    @State private var selectedId: String?

    var body: some View {
        OverlayScreenHost(title: orderId != nil ? L10n.addressListTitle : L10n.profileShippingAddresses, onDismiss: onDismiss) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: spacing.spacing2) {
                    Text(L10n.addressListHeader)
                        .font(FashTypography.headlineSmall)
                        .foregroundStyle(FashColors.textPrimary)
                    Text(orderId != nil ? L10n.addressListSubtitle : L10n.addressListSubtitleManage)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, spacing.spacing4)
                .padding(.top, spacing.spacing4)
                if addressVM.loading && addressVM.addresses.isEmpty {
                    ProgressView().padding()
                } else if addressVM.addresses.isEmpty {
                    VStack(spacing: spacing.spacing3) {
                        Text(L10n.addressEmptyAlertBody)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                        FashPrimaryButton(title: L10n.addressEmptyAlertCreate) {
                            onAddAddress?()
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: spacing.spacing3) {
                            ForEach(addressVM.addresses, id: \.id) { addr in
                                ShippingAddressSelectableCard(
                                    address: addr,
                                    isSelected: selectedId == addr.id,
                                    onSelect: { selectedId = addr.id },
                                    onSetDefault: {
                                        Task { await addressVM.setDefaultAddress(deps: deps, addressId: addr.id) }
                                    }
                                )
                            }
                        }
                        .padding(spacing.spacing4)
                    }
                    HStack(spacing: spacing.spacing3) {
                        Button(L10n.addressAddNew) { onAddAddress?() }
                            .font(FashTypography.labelLarge)
                        Spacer()
                        FashPrimaryButton(title: confirmTitle, action: confirmSelection)
                            .frame(width: 160)
                    }
                    .padding(spacing.spacing4)
                }
            }
        }
        .task {
            await addressVM.refresh(deps: deps)
            selectInitialAddress()
        }
        .onChange(of: addressVM.addresses.map(\.id).joined(separator: ",")) { _, _ in
            selectInitialAddress()
        }
    }

    private var confirmTitle: String {
        orderId != nil ? L10n.addressConfirm : L10n.addressDone
    }

    private func selectInitialAddress() {
        if let oid = orderId {
            selectedId = addressVM.initialSelectionIdForOrder(deps: deps, orderId: oid)
        } else {
            selectedId = addressVM.addresses.first(where: \.isDefault)?.id ?? addressVM.addresses.first?.id
        }
    }

    private func confirmSelection() {
        guard let id = selectedId, let addr = addressVM.addressById(id) else { return }
        if let orderId {
            Task {
                await addressVM.setOrderShipping(deps: deps, orderId: orderId, address: addr)
                onDismiss()
            }
        } else {
            onDismiss()
        }
    }
}
