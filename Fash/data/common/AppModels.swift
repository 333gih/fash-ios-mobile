import Foundation

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

struct OrderItem: Identifiable, Hashable {
    var id: String { orderId }
    let orderId: String
    let listingId: String
    let title: String
    let imageUrl: String
    let sellerUsername: String
    let priceVnd: Int64
    let status: String
    let canConfirm: Bool
    let canReview: Bool
    let createdAt: String
}

struct ProfileInfo: Equatable {
    let userId: String
    let username: String
    let displayName: String
    let avatarUrl: String
    let coverImageUrl: String
    let followerCount: Int
    let followingCount: Int
    let productCount: Int
    let bio: String
}
