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
}

struct PriceOffer: Equatable {
    let offerId: String
    let amountVnd: Int64
    let status: String
    let proposedByUserId: String
}

struct MeetingAppointmentPayload: Equatable {
    let appointmentId: String
    let status: String
    let locationUrl: String
    let scheduledAt: String
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
}

struct ConversationDetail: Equatable {
    let conversationId: String
    let otherUser: ChatOtherUser
    let product: ChatProductCard?
    let isBuyer: Bool
    let orderId: String?
    let offerCount: Int
    let isClosed: Bool
    var messages: [ChatMessage] = []
    var pendingOffer: PriceOffer?
}

struct ConversationListingGroup: Equatable {
    let listingId: String
    let listingTitle: String
    let listingImageUrl: String
    let conversations: [ConversationItem]
}

struct MeetingCheckInResult: Equatable {
    let appointmentId: String
    let buyerCheckInAt: String?
    let sellerCheckInAt: String?
}

struct MeetingCancelResult: Equatable {
    let appointmentId: String
    let status: String
}
