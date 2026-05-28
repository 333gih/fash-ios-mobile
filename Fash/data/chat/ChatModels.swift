import Foundation

// MARK: - Chat / C2C DTOs (Android: data/chat/ChatRepository.kt model section)

enum OutboundSendState: Equatable {
    case none
    case sending
    case failed
}

struct ConversationItem: Identifiable, Hashable {
    var id: String { conversationId }
    let conversationId: String
    let otherUserId: String
    let username: String
    let displayName: String
    let avatarUrl: String
    let lastMessageText: String
    let lastMessageType: String
    let timestamp: String
    let productThumbnailUrl: String
    let productTitle: String
    let productId: String
    let productPrice: Int64
    let hasUnread: Bool
    let unreadCount: Int
    let buyerUserId: String
    let sellerUserId: String
    let lastOfferAmountVnd: Int64
    let lastOfferFromBuyer: Bool
    let pendingOfferAmountVnd: Int64
}

struct ChatOtherUser: Equatable {
    let userId: String
    let displayName: String
    let username: String
    let avatarUrl: String
}

struct ChatProductCard: Equatable {
    let listingId: String
    let title: String
    let priceVnd: Int64
    let imageUrl: String
    let listingStatus: String

    var isSold: Bool { listingStatus == "sold" }
    var isReserved: Bool { listingStatus == "reserved" }
}

struct PriceOffer: Equatable {
    let offerId: String
    let amountVnd: Int64
    let status: String
    var proposedByMe: Bool
}

struct MeetingAppointmentPayload: Equatable {
    let appointmentId: String
    let status: String
    let locationUrl: String
    let scheduledAt: String
    let reminderOffsetMinutes: Int
    let reminderEnabled: Bool
    let proposerId: String
    let isProposerMe: Bool
    let buyerCheckInAt: String
    let sellerCheckInAt: String
    let buyerOnMyWayAt: String
    let sellerOnMyWayAt: String
    let safeZoneName: String
}

struct MyConversationReport: Equatable {
    let reportId: String
    let reportedUserId: String
    let category: String
    let createdAt: String
    let status: String
}

struct ChatMessage: Identifiable, Equatable {
    var id: String { messageId }
    let messageId: String
    let text: String
    let isFromMe: Bool
    let timestamp: String
    let isRead: Bool
    let senderId: String
    let messageType: String
    let offerAmountVnd: Int64
    let offerStatus: String
    let outboundState: OutboundSendState
    let systemSubtype: String?
    let meetingAppointment: MeetingAppointmentPayload?

    var isOfferType: Bool {
        messageType == "offer" || messageType == "counter_offer"
    }
}

struct ConversationDetail: Equatable {
    let conversationId: String
    let otherUser: ChatOtherUser
    let product: ChatProductCard?
    let isBuyer: Bool
    let orderId: String?
    let offerCount: Int
    let isClosed: Bool
    var pendingOffer: PriceOffer?
    var myReport: MyConversationReport?

    var hasOrder: Bool { orderId?.isEmpty == false }
}

struct ConversationListingGroup: Equatable {
    let listingId: String
    let listingTitle: String
    let listingImageUrl: String
    let conversations: [ConversationItem]
}

struct MeetingCheckInResult: Equatable {
    let endpointAvailable: Bool
    let alreadyCheckedIn: Bool
    let yourCheckInAt: String?
    let role: String?
    let meetingAppointment: MeetingAppointmentPayload?
}

struct MeetingCancelResult: Equatable {
    let suggestSellerReopenListing: Bool
}

struct CounterOfferSheetArgs: Equatable, Identifiable {
    var id: String { buyerOfferMessageId }
    let buyerOfferMessageId: String
    let buyerOfferAmountVnd: Int64
}
