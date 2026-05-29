import Foundation

enum OrderBuyerCancelPolicy {
    private static let buyerCancellableStatuses: Set<String> = [
        "fulfillment_pending",
        "payment_pending",
        "cash_meetup_open",
    ]

    static func buyerCanCancel(status: String?) -> Bool {
        let norm = (status ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return buyerCancellableStatuses.contains(norm)
    }
}
