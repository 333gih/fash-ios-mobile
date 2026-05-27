import SwiftUI

struct CheckoutScreen: View {
    @Environment(AppDependencies.self) private var deps
    let listingId: String
    var onDismiss: () -> Void

    @State private var viewModel = CheckoutViewModel()

    var body: some View {
        FashScreenScaffold(title: L10n.checkoutTitle, showBack: true, onBack: onDismiss) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = viewModel.loadError, viewModel.item == nil {
                        FashEmptyStateView(title: error, actionTitle: L10n.feedRetry) {
                            Task { await viewModel.load(listingId: listingId, deps: deps) }
                        }
                    } else {
                        if let item = viewModel.item {
                            checkoutRow(title: L10n.checkoutSectionProduct, value: item.title)
                            checkoutRow(title: L10n.checkoutProductPrice, value: FeedPriceFormat.format(viewModel.productPriceVnd))
                            checkoutRow(title: L10n.checkoutShippingFee, value: FeedPriceFormat.format(viewModel.shippingFeeVnd))
                            checkoutRow(title: L10n.checkoutTotal, value: FeedPriceFormat.format(viewModel.grandTotalVnd))
                        }
                        sectionHeader(L10n.checkoutAddress)
                        textField(L10n.checkoutFullName, text: $viewModel.fullName)
                        textField(L10n.checkoutPhone, text: $viewModel.phone)
                        textField(L10n.checkoutAddressLabel, text: $viewModel.address)
                        textField(L10n.checkoutDistrict, text: $viewModel.district)
                        textField(L10n.checkoutCity, text: $viewModel.city)
                        if let err = viewModel.paymentMethodsError {
                            Text(err)
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.error)
                        } else if !viewModel.paymentMethods.isEmpty {
                            sectionHeader(L10n.checkoutPaymentMethodLabel)
                            Picker(L10n.checkoutPaymentMethodLabel, selection: $viewModel.selectedPaymentIndex) {
                                ForEach(Array(viewModel.paymentMethods.enumerated()), id: \.offset) { index, method in
                                    Text(method.name).tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        if let status = viewModel.statusMessage {
                            Text(status)
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                        FashPrimaryButton(title: viewModel.isSubmitting ? L10n.checkoutProcessingOverlay : L10n.checkoutConfirmPay) {
                            Task { await viewModel.submitPayment(deps: deps) }
                        }
                        .disabled(viewModel.isSubmitting || viewModel.item == nil)
                    }
                }
                .padding(20)
            }
        }
        .task(id: listingId) {
            await viewModel.load(listingId: listingId, deps: deps)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(FashTypography.titleSmall)
            .foregroundStyle(FashColors.textPrimary)
            .padding(.top, 8)
    }

    private func checkoutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            Spacer()
            Text(value)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textPrimary)
        }
    }

    private func textField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.roundedBorder)
    }
}
