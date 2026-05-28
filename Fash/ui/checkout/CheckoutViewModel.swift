import Foundation
import Observation
import UIKit

private let defaultShippingFeeVnd: Int64 = 30_000

@Observable
@MainActor
final class CheckoutViewModel {
    var item: ListingFeedItem?
    var fullName = ""
    var phone = ""
    var address = ""
    var district = ""
    var city = ""
    var paymentMethods: [PaymentGatewayOption] = []
    var selectedPaymentIndex = 0
    var isLoading = false
    var isSubmitting = false
    var loadError: String?
    var paymentMethodsError: String?
    var statusMessage: String?

    var productPriceVnd: Int64 {
        item?.priceVnd ?? 0
    }

    var shippingFeeVnd: Int64 { defaultShippingFeeVnd }

    var grandTotalVnd: Int64 {
        max(0, productPriceVnd + shippingFeeVnd)
    }

    func load(listingId: String, deps: AppDependencies) async {
        guard !listingId.isEmpty else {
            loadError = L10n.checkoutLoadError
            return
        }
        isLoading = true
        loadError = nil
        paymentMethodsError = nil
        defer { isLoading = false }

        async let listingResult = deps.listingRepository.getListingDetail(listingId: listingId, publicBrowse: false)
        async let methodsResult = deps.corePaymentRepository.listPaymentMethods()

        switch await listingResult {
        case .success(let detail):
            item = detail
        case .failure(let error):
            loadError = FashErrorPresentation.userMessage(for: error)
        }

        switch await methodsResult {
        case .success(let methods):
            if methods.isEmpty {
                paymentMethods = []
                paymentMethodsError = L10n.checkoutPaymentMethodsUnavailable
            } else {
                paymentMethods = methods
                selectedPaymentIndex = 0
            }
        case .failure:
            paymentMethods = []
            paymentMethodsError = L10n.checkoutPaymentMethodsLoadFailed
        }

        if fullName.isEmpty {
            if case .success(let profile) = await deps.userRepository.getMeProfile() {
                fullName = profile.displayName.isEmpty ? profile.username : profile.displayName
            }
        }
    }

    func submitPayment(deps: AppDependencies) async {
        guard let item else { return }
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = L10n.checkoutMissingAddressHint
            return
        }
        guard !paymentMethods.isEmpty else {
            statusMessage = paymentMethodsError ?? L10n.checkoutPaymentMethodsUnavailable
            return
        }
        isSubmitting = true
        statusMessage = nil
        defer { isSubmitting = false }

        let orderResult = await deps.orderRepository.createOrder(
            listingId: item.id,
            amountVnd: grandTotalVnd,
            shippingFeeVnd: shippingFeeVnd
        )
        guard case .success(let orderId) = orderResult else {
            statusMessage = L10n.checkoutPaymentError
            return
        }

        let method = paymentMethods[selectedPaymentIndex]
        let shipping = CheckoutAddressPayload(
            fullName: fullName,
            phone: phone,
            address: address,
            district: district,
            city: city
        )
        let payResult = await deps.corePaymentRepository.initiatePayment(
            orderId: orderId,
            paymentMethod: method.id,
            redirectUrl: BuildConfig.paymentRedirectURL,
            shipping: shipping
        )
        switch payResult {
        case .success(let result):
            if let url = URL(string: result.paymentUrl) {
                await UIApplication.shared.open(url)
                statusMessage = L10n.checkoutAwaitingGateway
            } else {
                statusMessage = L10n.checkoutPaymentInitFailed
            }
        case .failure(let error):
            statusMessage = FashErrorPresentation.userMessage(for: error)
        }
    }
}
