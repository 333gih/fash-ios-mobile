import Foundation

// MARK: - Offline C2C deal DTOs (Android: data/deal/DealRepository.kt)

struct DealRecord: Equatable {
    var dealId: String
    var conversationId: String
    var listingId: String
    var status: String
    var amountVnd: Int64
    var completedAt: String?
}

struct ReviewBadgeRefPayload: Equatable {
    let badgeId: String
    let slug: String
}
