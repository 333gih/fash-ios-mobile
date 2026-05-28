import Foundation

/// Sub-tab filter for orders list — Android `OrderStatusFilter`.
enum OrderStatusFilter: CaseIterable, Hashable {
    case all
    case paymentPending
    case paymentHeld
    case inTransit
    case deliveredConfirmed
    case cancelled
    case disputed

    var apiQuery: String? {
        switch self {
        case .all: return nil
        case .paymentPending: return "payment_pending"
        case .paymentHeld: return "payment_held"
        case .inTransit: return "in_transit"
        case .deliveredConfirmed: return "delivered_confirmed"
        case .cancelled: return "cancelled"
        case .disputed: return "disputed"
        }
    }

    var label: String {
        switch self {
        case .all: return L10n.ordersChipAll
        case .paymentPending: return L10n.ordersChipPaymentPending
        case .paymentHeld: return L10n.ordersChipPaymentHeld
        case .inTransit: return L10n.ordersChipInTransit
        case .deliveredConfirmed: return L10n.ordersChipDelivered
        case .cancelled: return L10n.ordersChipCancelled
        case .disputed: return L10n.ordersChipDisputed
        }
    }

    func matches(_ order: OrderItem) -> Bool {
        if self == .all { return true }
        let norm = OrderFormatting.normalizeStatus(order.status)
        switch self {
        case .all: return true
        case .paymentPending: return norm == "payment_pending"
        case .paymentHeld: return norm == "payment_held"
        case .inTransit: return norm == "in_transit"
        case .deliveredConfirmed: return norm == "delivered_confirmed"
        case .cancelled: return norm == "cancelled"
        case .disputed: return norm == "disputed"
        }
    }
}
