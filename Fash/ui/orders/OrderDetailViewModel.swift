import Foundation
import Observation

@Observable
@MainActor
final class OrderDetailViewModel {
    var detail: OrderDetailPayload?
    var isLoading = true
    var isRefreshing = false
    var loadError: String?
    var busyAction: OrderDetailBusyAction = .none
    var toastMessage: String?
    var shipmentCarriers: [ShipmentCarrier] = []

    private var requestedOrderId: String?

    func load(orderId: String, deps: AppDependencies) async {
        let clean = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            loadError = L10n.orderDetailLoadError
            isLoading = false
            return
        }
        let switching = requestedOrderId?.caseInsensitiveCompare(clean) != .orderedSame
        requestedOrderId = clean
        if switching {
            detail = nil
            busyAction = .none
            isLoading = true
            isRefreshing = false
        } else if detail != nil {
            isRefreshing = true
        } else {
            isLoading = true
        }
        loadError = nil
        let previous = detail
        let result = await deps.orderRepository.getOrderDetail(orderId: clean)
        guard requestedOrderId?.caseInsensitiveCompare(clean) == .orderedSame else { return }
        isLoading = false
        isRefreshing = false
        switch result {
        case .success(let payload):
            detail = OrderDetailLogic.mergePreservingMeetupGrace(
                fresh: payload,
                previous: previous?.orderId.caseInsensitiveCompare(clean) == .orderedSame ? previous : nil
            )
        case .failure(let error):
            if detail == nil {
                loadError = FashErrorPresentation.userMessage(for: error)
            } else {
                toastMessage = FashErrorPresentation.userMessage(for: error)
            }
        }
    }

    func viewerRole(deps: AppDependencies) -> OrderViewerRole {
        guard let d = detail else { return .viewer }
        let my = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return OrderDetailLogic.viewerRole(detail: d, myUserId: my)
    }

    func isCurrentUserBuyer(deps: AppDependencies) -> Bool { viewerRole(deps: deps) == .buyer }
    func isCurrentUserSeller(deps: AppDependencies) -> Bool { viewerRole(deps: deps) == .seller }

    func loadShipmentCarriers(deps: AppDependencies) async {
        guard case .success(let list) = await deps.orderRepository.listShipmentCarriers() else { return }
        shipmentCarriers = list
    }

    func confirmReceipt(deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        busyAction = .confirmReceipt
        defer { busyAction = .none }
        switch await deps.orderRepository.confirmReceipt(orderId: id) {
        case .success:
            toastMessage = L10n.ordersConfirmSuccess
            await load(orderId: id, deps: deps)
        case .failure:
            toastMessage = L10n.ordersConfirmError
        }
    }

    func confirmHandoff(deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        busyAction = .confirmHandoff
        defer { busyAction = .none }
        switch await deps.orderRepository.confirmHandoff(orderId: id) {
        case .success:
            toastMessage = L10n.orderDetailConfirmHandoffSuccess
            await load(orderId: id, deps: deps)
        case .failure:
            toastMessage = L10n.orderDetailConfirmHandoffError
        }
    }

    func acknowledgeOfflineCash(deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        busyAction = .acknowledgeCash
        defer { busyAction = .none }
        switch await deps.orderRepository.acknowledgeOfflineCash(orderId: id) {
        case .success:
            toastMessage = L10n.orderDetailAckCashOk
            await load(orderId: id, deps: deps)
        case .failure(let error):
            toastMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func checkInAtMeeting(deps: AppDependencies) async {
        guard let apptId = detail?.meetingAppointment?.id, !apptId.isEmpty,
              let orderId = detail?.orderId else { return }
        busyAction = .checkIn
        defer { busyAction = .none }
        switch await deps.chatRepository.checkInMeeting(appointmentId: apptId) {
        case .success(let r):
            if !r.endpointAvailable {
                toastMessage = L10n.orderDetailMeetingCheckInRefreshOnly
            } else if r.alreadyCheckedIn {
                toastMessage = L10n.orderDetailMeetingCheckInAlready
            } else {
                toastMessage = L10n.orderDetailMeetingCheckInOk
                applyOptimisticMeetupCheckIn(deps: deps)
            }
            await load(orderId: orderId, deps: deps)
        case .failure(let error):
            toastMessage = mapCheckInError(error)
        }
    }

    func reportMeetingNoShow(reason: String, note: String, deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        busyAction = .reportNoShow
        defer { busyAction = .none }
        switch await deps.orderRepository.reportMeetingNoShow(orderId: id, reason: reason, note: note) {
        case .success:
            toastMessage = L10n.orderDetailReportNoShowOk
            await load(orderId: id, deps: deps)
        case .failure(let error):
            toastMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func shipOrder(tracking: String, carrier: String, deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        let tn = tracking.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tn.isEmpty else {
            toastMessage = L10n.orderDetailShipTrackingRequired
            return
        }
        busyAction = .ship
        defer { busyAction = .none }
        switch await deps.orderRepository.shipOrder(orderId: id, trackingNumber: tn, carrier: carrier) {
        case .success:
            toastMessage = L10n.orderDetailShipSuccess
            await load(orderId: id, deps: deps)
        case .failure(let error):
            toastMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func bookShipment(carrierId: String, deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        busyAction = .ship
        defer { busyAction = .none }
        switch await deps.orderRepository.bookShipment(orderId: id, carrierId: carrierId) {
        case .success:
            toastMessage = L10n.orderDetailShipSuccess
            await load(orderId: id, deps: deps)
        case .failure(let error):
            toastMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    func submitReview(rating: Int, comment: String?, deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        busyAction = .submitReview
        defer { busyAction = .none }
        switch await deps.orderRepository.submitReview(orderId: id, rating: rating, comment: comment) {
        case .success:
            toastMessage = L10n.orderDetailReviewSent
            await load(orderId: id, deps: deps)
        case .failure:
            toastMessage = L10n.orderDetailReviewError
        }
    }

    @discardableResult
    func openDispute(description: String, photoUrls: [String], deps: AppDependencies) async -> Bool {
        guard let id = detail?.orderId, !id.isEmpty else { return false }
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            toastMessage = L10n.orderDetailDisputeDescriptionRequired
            return false
        }
        busyAction = .openDispute
        defer { busyAction = .none }
        switch await deps.orderRepository.openDispute(orderId: id, description: description, photoUrls: photoUrls) {
        case .success:
            toastMessage = L10n.orderDetailDisputeOpenSuccess
            await load(orderId: id, deps: deps)
            return true
        case .failure(let error):
            toastMessage = FashErrorPresentation.userMessage(for: error).nilIfEmpty ?? L10n.orderDetailDisputeError
            return false
        }
    }

    @discardableResult
    func submitDisputeEvidence(description: String, photoUrls: [String], deps: AppDependencies) async -> Bool {
        guard let id = detail?.orderId, !id.isEmpty else { return false }
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            toastMessage = L10n.orderDetailDisputeDescriptionRequired
            return false
        }
        busyAction = .submitEvidence
        defer { busyAction = .none }
        switch await deps.orderRepository.submitDisputeEvidence(orderId: id, description: description, photoUrls: photoUrls) {
        case .success:
            toastMessage = L10n.orderDetailDisputeEvidenceSuccess
            await load(orderId: id, deps: deps)
            return true
        case .failure(let error):
            toastMessage = FashErrorPresentation.userMessage(for: error).nilIfEmpty ?? L10n.orderDetailDisputeError
            return false
        }
    }

    func cancelOrder(reasonCode: String, note: String, deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        busyAction = .cancelOrder
        defer { busyAction = .none }
        switch await deps.orderRepository.cancelOrder(orderId: id, reasonCode: reasonCode, reasonNote: note) {
        case .success:
            toastMessage = L10n.orderCancelSuccess
            await load(orderId: id, deps: deps)
        case .failure(let error):
            toastMessage = FashErrorPresentation.userMessage(for: error)
        }
    }

    private func applyOptimisticMeetupCheckIn(deps: AppDependencies) {
        guard var d = detail, var g = d.meetingGrace else { return }
        let stamp = isoTimestampUtcNow()
        if isCurrentUserBuyer(deps: deps), g.buyerCheckedInAt.isEmpty {
            g.buyerCheckedInAt = stamp
            g.selfCheckedIn = true
            g.canCheckIn = false
        } else if isCurrentUserSeller(deps: deps), g.sellerCheckedInAt.isEmpty {
            g.sellerCheckedInAt = stamp
            g.selfCheckedIn = true
            g.canCheckIn = false
        }
        d.meetingGrace = g
        if var appt = d.meetingAppointment {
            if isCurrentUserBuyer(deps: deps), appt.buyerCheckInAt.isEmpty { appt.buyerCheckInAt = stamp }
            if isCurrentUserSeller(deps: deps), appt.sellerCheckInAt.isEmpty { appt.sellerCheckInAt = stamp }
            d.meetingAppointment = appt
        }
        detail = d
    }

    private func isoTimestampUtcNow() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: Date())
    }

    private func mapCheckInError(_ error: Error) -> String {
        let m = (error as? CoreServiceHttpException)?.message ?? error.localizedDescription
        if m.localizedCaseInsensitiveContains("MEETING_CHECK_IN_WINDOW") { return L10n.chatMeetingCheckInWindowError }
        return m.isEmpty ? L10n.orderDetailLoadError : m
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
