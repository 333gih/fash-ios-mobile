import Foundation

// MARK: - Order list / detail DTOs (Android: data/order/)

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

struct OrderMeetingAppointment: Equatable {
    var id: String
    var status: String
    var locationUrl: String
    var scheduledAt: String
    var reminderOffsetMinutes: Int
    var reminderEnabled: Bool
    var reminderSentAt: String
    var createdAt: String
    var updatedAt: String
    var buyerCheckInAt: String
    var sellerCheckInAt: String
}

struct OrderMeetingGrace: Equatable {
    var canCheckIn: Bool
    var selfCheckedIn: Bool
    var canReportNoShow: Bool
    var sosUnlocked: Bool
    var checkInHint: String
    var noShowHint: String
    var buyerCheckedInAt: String
    var sellerCheckedInAt: String
    var phase: String
}

extension OrderMeetingGrace {
    func viewerShouldShowCheckIn(isBuyer: Bool, appointment: OrderMeetingAppointment?) -> Bool {
        guard canCheckIn, !selfCheckedIn else { return false }
        let graceSelfAt = isBuyer ? buyerCheckedInAt : sellerCheckedInAt
        if !graceSelfAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        guard let appt = appointment else { return true }
        let apptSelfAt = isBuyer ? appt.buyerCheckInAt : appt.sellerCheckInAt
        return apptSelfAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct OrderBuyerReview: Equatable {
    var id: String
    var rating: Int
    var comment: String
    var createdAt: String
}

/// Full order payload from `GET /api/v1/orders/{order_id}` — Android `OrderDetail`.
struct OrderDetailPayload: Equatable {
    var orderId: String = ""
    var listingId: String = ""
    var buyerUserId: String = ""
    var sellerUserId: String = ""
    var amountVnd: Int64 = 0
    var platformFeeVnd: Int64 = 0
    var sellerPayoutVnd: Int64 = 0
    var status: String = "payment_pending"
    var fulfillmentChannel: String = ""
    var trackingNumber: String = ""
    var carrier: String = ""
    var listingTitle: String = ""
    var listingImageUrl: String = ""
    var listingPriceVnd: Int64 = 0
    var listingStatus: String = "active"
    var sellerUsername: String = ""
    var sellerDisplayName: String = ""
    var sellerAvatarUrl: String = ""
    var buyerUsername: String = ""
    var buyerDisplayName: String = ""
    var buyerAvatarUrl: String = ""
    var conversationId: String = ""
    var canConfirmReceipt: Bool = false
    var canCancel: Bool = false
    var canReview: Bool = false
    var shippingFeeVnd: Int64 = 0
    var discountVnd: Int64 = 0
    var buyerTotalVnd: Int64 = 0
    var recipientName: String = ""
    var recipientPhone: String = ""
    var shippingAddressFormatted: String = ""
    var createdAt: String = ""
    var paidAt: String = ""
    var shippedAt: String = ""
    var deliveredAt: String = ""
    var cancelledAt: String = ""
    var expectedDeliveryAt: String = ""
    var shipByAt: String = ""
    var escrowReleaseAt: String = ""
    var disputeSummary: String = ""
    var listingVariantLabel: String = ""
    var trackingStatusSummary: String = ""
    var canShip: Bool = false
    var canConfirmHandoff: Bool = false
    var canAcknowledgeOfflineCash: Bool = false
    var meetupDeadlineAt: String = ""
    var orderExpiresAt: String = ""
    var remainingSeconds: Int64 = 0
    var expiryKind: String = ""
    var meetingAppointment: OrderMeetingAppointment?
    var meetingGrace: OrderMeetingGrace?
    var buyerReview: OrderBuyerReview?

    var effectiveBuyerTotal: Int64 {
        if buyerTotalVnd > 0 { return buyerTotalVnd }
        return max(0, amountVnd + shippingFeeVnd - discountVnd)
    }
}
