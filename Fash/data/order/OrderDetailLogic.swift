import Foundation
import SwiftUI

enum OrderViewerRole {
    case buyer
    case seller
    case viewer
}

enum TimelineStepState {
    case done
    case current
}

struct TimelineStepUi: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let state: TimelineStepState
}

enum OrderDetailLogic {
    static func viewerRole(detail: OrderDetailPayload, myUserId: String) -> OrderViewerRole {
        let my = myUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !my.isEmpty else { return .viewer }
        if !detail.buyerUserId.isEmpty, my.caseInsensitiveCompare(detail.buyerUserId) == .orderedSame { return .buyer }
        if !detail.buyerUsername.isEmpty, my.caseInsensitiveCompare(detail.buyerUsername) == .orderedSame { return .buyer }
        if !detail.sellerUserId.isEmpty, my.caseInsensitiveCompare(detail.sellerUserId) == .orderedSame { return .seller }
        if !detail.sellerUsername.isEmpty, my.caseInsensitiveCompare(detail.sellerUsername) == .orderedSame { return .seller }
        return .viewer
    }

    static func isMeetupStyleOrder(_ d: OrderDetailPayload) -> Bool {
        d.meetingAppointment != nil
            && d.trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && d.carrier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func sellerShowsConfirmHandoffCta(_ d: OrderDetailPayload) -> Bool {
        if d.canConfirmHandoff { return true }
        guard let g = d.meetingGrace else { return false }
        let bothCheckedIn: Bool = {
            if g.sosUnlocked { return true }
            return !g.buyerCheckedInAt.isEmpty && !g.sellerCheckedInAt.isEmpty
        }()
        guard bothCheckedIn else { return false }
        let st = OrderFormatting.normalizeStatus(d.status)
        return st == "payment_held" || st == "cash_meetup_open"
    }

    static func timelineSteps(_ d: OrderDetailPayload, formatDate: (String) -> String) -> [TimelineStepUi] {
        let st = OrderFormatting.normalizeStatus(d.status)
        func date(_ iso: String) -> String {
            let t = iso.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? "" : formatDate(t)
        }
        switch st {
        case "cancelled":
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineCancelled, subtitle: date(d.cancelledAt), state: .current),
            ]
        case "disputed":
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineDisputeOpen, subtitle: d.disputeSummary, state: .current),
            ]
        case "fulfillment_pending":
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineChooseFulfillment, subtitle: "", state: .current),
            ]
        case "payment_pending":
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineWaitingPayment, subtitle: "", state: .current),
            ]
        case "cash_meetup_open":
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineCashMeetup, subtitle: "", state: .current),
            ]
        case "payment_held":
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelinePaid, subtitle: date(d.paidAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelinePreparing, subtitle: L10n.orderTimelinePreparingSub, state: .current),
            ]
        case "in_transit":
            if isMeetupStyleOrder(d) {
                return [
                    TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                    TimelineStepUi(title: L10n.orderTimelinePaid, subtitle: date(d.paidAt), state: .done),
                    TimelineStepUi(title: L10n.orderTimelineMeetupHandoff, subtitle: "", state: .done),
                    TimelineStepUi(
                        title: L10n.orderTimelineMeetupAwaitingBuyer,
                        subtitle: L10n.orderTimelineMeetupAwaitingBuyerSub,
                        state: .current
                    ),
                ]
            }
            let transitSub = d.trackingStatusSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? date(d.expectedDeliveryAt)
                : d.trackingStatusSummary
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelinePaid, subtitle: date(d.paidAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineShipped, subtitle: date(d.shippedAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineInTransit, subtitle: transitSub, state: .current),
            ]
        case "delivered_confirmed":
            if isMeetupStyleOrder(d) {
                return [
                    TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                    TimelineStepUi(title: L10n.orderTimelinePaid, subtitle: date(d.paidAt), state: .done),
                    TimelineStepUi(title: L10n.orderTimelineMeetupHandoff, subtitle: "", state: .done),
                    TimelineStepUi(title: L10n.orderTimelineDelivered, subtitle: date(d.deliveredAt), state: .done),
                ]
            }
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelinePaid, subtitle: date(d.paidAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineShipped, subtitle: date(d.shippedAt), state: .done),
                TimelineStepUi(title: L10n.orderTimelineDelivered, subtitle: date(d.deliveredAt), state: .done),
            ]
        default:
            return [
                TimelineStepUi(title: L10n.orderTimelinePlaced, subtitle: date(d.createdAt), state: .done),
                TimelineStepUi(title: OrderFormatting.statusLabel(d.status), subtitle: "", state: .current),
            ]
        }
    }

    static func heroContent(
        _ d: OrderDetailPayload,
        role: OrderViewerRole,
        formatDate: (String) -> String
    ) -> (title: String, subtitle: String, useAccent: Bool) {
        let st = OrderFormatting.normalizeStatus(d.status)
        switch st {
        case "fulfillment_pending":
            return (L10n.orderStatusFulfillmentPending, L10n.orderHeroFulfillmentPendingSub, true)
        case "payment_pending":
            switch role {
            case .seller:
                return (L10n.orderHeroSellerWaitPaymentTitle, L10n.orderHeroSellerWaitPaymentSub, true)
            default:
                return (L10n.orderHeroBuyerPaymentPendingTitle, L10n.orderHeroBuyerPaymentPendingSub, true)
            }
        case "cash_meetup_open":
            return (L10n.orderStatusCashMeetupOpen, L10n.orderHeroCashMeetupSub, true)
        case "payment_held":
            switch role {
            case .seller:
                let shipBy = d.shipByAt.trimmingCharacters(in: .whitespacesAndNewlines)
                let sub = shipBy.isEmpty
                    ? L10n.orderHeroSellerPrepareSub
                    : L10n.orderHeroSellerPrepareSubDeadline(formatDate(shipBy))
                return (L10n.orderHeroSellerPrepareTitle, sub, true)
            default:
                return (L10n.orderHeroBuyerPaymentHeldTitle, L10n.orderHeroBuyerPaymentHeldSub, true)
            }
        case "in_transit":
            let eta = d.expectedDeliveryAt.trimmingCharacters(in: .whitespacesAndNewlines)
            let sub = eta.isEmpty ? L10n.orderHeroInTransitSub : L10n.orderHeroEtaLine(formatDate(eta))
            return (L10n.orderStatusInTransit, sub, true)
        case "delivered_confirmed":
            let sub = d.deliveredAt.isEmpty ? L10n.orderHeroCompletedSub("") : L10n.orderHeroCompletedSub(formatDate(d.deliveredAt))
            return (L10n.orderStatusDeliveredConfirmed, sub, true)
        case "cancelled":
            let sub = d.cancelledAt.isEmpty ? L10n.orderHeroCancelledSubGeneric : L10n.orderHeroCancelledSub(formatDate(d.cancelledAt))
            return (L10n.orderStatusCancelled, sub, false)
        case "disputed":
            let sub = d.disputeSummary.trimmingCharacters(in: .whitespacesAndNewlines)
            return (L10n.orderStatusDisputed, sub.isEmpty ? L10n.orderHeroDisputedSub : sub, false)
        default:
            return (OrderFormatting.statusLabel(d.status), "", true)
        }
    }

    static func mergePreservingMeetupGrace(fresh: OrderDetailPayload, previous: OrderDetailPayload?) -> OrderDetailPayload {
        guard let prev = previous, prev.orderId.caseInsensitiveCompare(fresh.orderId) == .orderedSame else {
            return fresh
        }
        var merged = fresh
        if let fGrace = fresh.meetingGrace, let pGrace = prev.meetingGrace {
            merged.meetingGrace = OrderMeetingGrace(
                canCheckIn: fGrace.canCheckIn && !fGrace.selfCheckedIn && !pGrace.selfCheckedIn,
                selfCheckedIn: fGrace.selfCheckedIn || pGrace.selfCheckedIn,
                canReportNoShow: fGrace.canReportNoShow,
                sosUnlocked: fGrace.sosUnlocked,
                checkInHint: fGrace.checkInHint.isEmpty ? pGrace.checkInHint : fGrace.checkInHint,
                noShowHint: fGrace.noShowHint.isEmpty ? pGrace.noShowHint : fGrace.noShowHint,
                buyerCheckedInAt: fGrace.buyerCheckedInAt.isEmpty ? pGrace.buyerCheckedInAt : fGrace.buyerCheckedInAt,
                sellerCheckedInAt: fGrace.sellerCheckedInAt.isEmpty ? pGrace.sellerCheckedInAt : fGrace.sellerCheckedInAt,
                phase: fGrace.phase
            )
        } else if fresh.meetingGrace == nil, let pGrace = prev.meetingGrace {
            merged.meetingGrace = pGrace
        }
        if let fAppt = fresh.meetingAppointment, let pAppt = prev.meetingAppointment,
           fAppt.id.caseInsensitiveCompare(pAppt.id) == .orderedSame {
            merged.meetingAppointment = OrderMeetingAppointment(
                id: fAppt.id,
                status: fAppt.status,
                locationUrl: fAppt.locationUrl,
                scheduledAt: fAppt.scheduledAt,
                reminderOffsetMinutes: fAppt.reminderOffsetMinutes,
                reminderEnabled: fAppt.reminderEnabled,
                reminderSentAt: fAppt.reminderSentAt,
                createdAt: fAppt.createdAt,
                updatedAt: fAppt.updatedAt,
                buyerCheckInAt: fAppt.buyerCheckInAt.isEmpty ? pAppt.buyerCheckInAt : fAppt.buyerCheckInAt,
                sellerCheckInAt: fAppt.sellerCheckInAt.isEmpty ? pAppt.sellerCheckInAt : fAppt.sellerCheckInAt
            )
        } else if fresh.meetingAppointment == nil {
            merged.meetingAppointment = prev.meetingAppointment
        }
        if merged.buyerReview == nil { merged.buyerReview = prev.buyerReview }
        if merged.buyerReview != nil { merged.canReview = false }
        return merged
    }
}
