import Foundation

// MARK: - Payment DTOs (Android: data/payment/CorePaymentRepository.kt)

struct PaymentGatewayOption: Equatable {
    let id: String
    let name: String
}

struct PaymentInitiateResult: Equatable {
    let paymentUrl: String
    let transactionId: String?
}

struct PaymentStatusResult: Equatable {
    let status: String
    let transactionId: String?
}

struct CheckoutAddressPayload: Equatable {
    let fullName: String
    let phone: String
    let address: String
    let district: String
    let city: String
}
