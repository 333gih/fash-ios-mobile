import Foundation

struct OrderCancelReasonOption: Identifiable, Equatable {
    let code: String
    let label: String
    var requiresNote: Bool = false
    var id: String { code }
}

enum OrderCancelReasons {
    static let options: [OrderCancelReasonOption] = [
        OrderCancelReasonOption(code: "changed_mind", label: L10n.orderCancelReasonChangedMind),
        OrderCancelReasonOption(code: "found_elsewhere", label: L10n.orderCancelReasonFoundElsewhere),
        OrderCancelReasonOption(code: "price_concern", label: L10n.orderCancelReasonPriceConcern),
        OrderCancelReasonOption(code: "shipping_not_suitable", label: L10n.orderCancelReasonShippingNotSuitable),
        OrderCancelReasonOption(code: "meetup_not_possible", label: L10n.orderCancelReasonMeetupNotPossible),
        OrderCancelReasonOption(code: "seller_slow", label: L10n.orderCancelReasonSellerSlow),
        OrderCancelReasonOption(code: "payment_problem", label: L10n.orderCancelReasonPaymentProblem),
        OrderCancelReasonOption(code: "other", label: L10n.orderCancelReasonOther, requiresNote: true),
    ]

    static func label(forCode code: String) -> String {
        let c = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return options.first { $0.code == c }?.label ?? code
    }
}
