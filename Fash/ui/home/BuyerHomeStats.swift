import Foundation

/// Buyer dashboard counts for the home journey row — Android [BuyerHomeStats].
struct BuyerHomeStats: Equatable {
    var activeDeliveryOrders: Int = 0
    var savedListingsCount: Int = 0
    var listingsInReviewCount: Int = 0

    func hasJourneyActivity() -> Bool {
        activeDeliveryOrders > 0 || savedListingsCount > 0 || listingsInReviewCount > 0
    }
}

enum BuyerHomeStatsConstants {
    static let deliveringStatuses: Set<String> = [
        "payment_held",
        "in_transit",
        "delivering",
        "shipped",
        "shipping",
    ]
}
