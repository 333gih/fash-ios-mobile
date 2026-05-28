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

    private var requestedOrderId: String?

    func load(orderId: String, deps: AppDependencies) async {
        let clean = orderId.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else {
            loadError = L10n.feedLoadError
            isLoading = false
            return
        }
        let switching = requestedOrderId != clean
        requestedOrderId = clean
        if switching {
            detail = nil
            isLoading = true
        } else if detail != nil {
            isRefreshing = true
        } else {
            isLoading = true
        }
        loadError = nil
        let result = await deps.orderRepository.getOrderDetail(orderId: clean)
        guard requestedOrderId == clean else { return }
        isLoading = false
        isRefreshing = false
        switch result {
        case .success(let payload):
            detail = payload
        case .failure(let error):
            if detail == nil { loadError = error.localizedDescription }
        }
    }

    func isCurrentUserBuyer(deps: AppDependencies) -> Bool {
        let my = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !my.isEmpty, let d = detail else { return false }
        if !d.buyerUserId.isEmpty, my.caseInsensitiveCompare(d.buyerUserId) == .orderedSame { return true }
        if !d.buyerUsername.isEmpty, my.caseInsensitiveCompare(d.buyerUsername) == .orderedSame { return true }
        return false
    }

    func isCurrentUserSeller(deps: AppDependencies) -> Bool {
        let my = deps.authSessionStore.read()?.userId?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !my.isEmpty, let d = detail else { return false }
        if !d.sellerUserId.isEmpty, my.caseInsensitiveCompare(d.sellerUserId) == .orderedSame { return true }
        if !d.sellerUsername.isEmpty, my.caseInsensitiveCompare(d.sellerUsername) == .orderedSame { return true }
        return false
    }

    func confirmReceipt(deps: AppDependencies) async {
        guard let id = detail?.orderId, !id.isEmpty else { return }
        busyAction = .confirmingReceipt
        defer { busyAction = .none }
        switch await deps.orderRepository.confirmReceipt(orderId: id) {
        case .success:
            toastMessage = L10n.ordersConfirmSuccess
            await load(orderId: id, deps: deps)
        case .failure:
            toastMessage = L10n.ordersConfirmError
        }
    }

    func shouldShowPayButton(deps: AppDependencies) -> Bool {
        guard let d = detail else { return false }
        return isCurrentUserBuyer(deps: deps) && OrderFormatting.normalizeStatus(d.status) == "payment_pending"
    }
}

enum OrderDetailBusyAction {
    case none
    case confirmingReceipt
}
