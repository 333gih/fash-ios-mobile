import Foundation

enum ChatOrderStatusCopy {
    static func normalize(_ raw: String?) -> String {
        raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    }

    static func subtitle(isBuyer: Bool, orderStatus: String?) -> String? {
        let norm = normalize(orderStatus)
        guard !norm.isEmpty else { return nil }
        if isBuyer {
            switch norm {
            case "payment_pending": return L10n.chatOrderStateBuyerPaymentPending
            case "payment_held": return L10n.chatOrderStateBuyerPaymentHeld
            case "in_transit": return L10n.chatOrderStateBuyerInTransit
            case "delivered_confirmed": return L10n.chatOrderStateBuyerDeliveredConfirmed
            case "cancelled": return L10n.chatOrderStateBuyerCancelled
            case "disputed": return L10n.chatOrderStateBuyerDisputed
            case "cash_meetup_open": return L10n.chatOrderStateBuyerCashMeetupOpen
            case "fulfillment_pending": return L10n.chatOrderStateBuyerFulfillmentPending
            default: return L10n.chatOrderStateBuyerUnknown(norm)
            }
        }
        switch norm {
        case "payment_pending": return L10n.chatOrderStateSellerPaymentPending
        case "payment_held": return L10n.chatOrderStateSellerPaymentHeld
        case "in_transit": return L10n.chatOrderStateSellerInTransit
        case "delivered_confirmed": return L10n.chatOrderStateSellerDeliveredConfirmed
        case "cancelled": return L10n.chatOrderStateSellerCancelled
        case "disputed": return L10n.chatOrderStateSellerDisputed
        case "cash_meetup_open": return L10n.chatOrderStateSellerCashMeetupOpen
        case "fulfillment_pending": return L10n.chatOrderStateSellerFulfillmentPending
        default: return L10n.chatOrderStateSellerUnknown(norm)
        }
    }

    static func dealBannerTitle(isBuyer: Bool, orderStatus: String?) -> String {
        let s = normalize(orderStatus)
        if isBuyer && s == "payment_pending" { return L10n.chatDealBannerBuyerPending }
        if !isBuyer && s == "payment_pending" { return L10n.chatDealBannerSellerPending }
        switch s {
        case "cancelled": return L10n.chatDealBannerCancelled
        case "disputed": return L10n.chatDealBannerDisputed
        case "delivered_confirmed": return L10n.chatDealBannerDelivered
        case "fulfillment_pending": return L10n.chatDealBannerChooseFulfillment
        case "cash_meetup_open": return L10n.chatDealBannerCashMeetup
        case "payment_held", "in_transit": return L10n.chatDealBannerInProgress
        case "": return L10n.chatDealBannerStatusPending
        default: return L10n.chatDealBannerDone
        }
    }
}

enum ChatOfferStatusLabel {
    static func text(for status: String) -> String {
        switch status.lowercased() {
        case "accepted": return L10n.chatOfferStatusAccepted
        case "declined": return L10n.chatOfferStatusDeclined
        case "expired": return L10n.chatOfferStatusExpired
        case "cancelled": return L10n.chatOfferStatusCancelled
        case "pending": return L10n.chatOfferStatusWaiting
        default: return L10n.chatOfferStatusCancelled
        }
    }
}
