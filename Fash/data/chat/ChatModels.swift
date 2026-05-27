import Foundation

enum OutboundSendState: Equatable {
    case none
    case sending
    case failed
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
}

struct UserSearchResult: Identifiable, Equatable {
    var id: String { userId.isEmpty ? username : userId }
    let userId: String
    let username: String
    let displayName: String
    let avatarUrl: String
    let followerCount: Int
    let verified: Bool
    let followingCount: Int
    let listingCount: Int
}

struct FollowListPage: Equatable {
    let items: [UserSearchResult]
    let total: Int
}

struct PaymentGatewayOption: Equatable {
    let id: String
    let name: String
}

struct PaymentInitiateResult: Equatable {
    let paymentUrl: String
    let transactionId: String?
}

struct CheckoutAddressPayload: Equatable {
    let fullName: String
    let phone: String
    let address: String
    let district: String
    let city: String
}
