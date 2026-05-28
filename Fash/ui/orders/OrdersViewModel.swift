import Foundation
import Observation

@Observable
@MainActor
final class OrdersViewModel {
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var buyingOrders: [OrderItem] = []
    var sellingOrders: [OrderItem] = []
    var selectedRole: OrderRole = .buying
    var buyingStatusFilter: OrderStatusFilter = .all
    var sellingStatusFilter: OrderStatusFilter = .all
    var confirmingOrderId: String?

    enum OrderRole: String, CaseIterable {
        case buying
        case selling
    }

    var activeStatusFilter: OrderStatusFilter {
        selectedRole == .buying ? buyingStatusFilter : sellingStatusFilter
    }

    var sourceOrders: [OrderItem] {
        selectedRole == .buying ? buyingOrders : sellingOrders
    }

    var filteredOrders: [OrderItem] {
        sourceOrders.filter { activeStatusFilter.matches($0) }
    }

    func selectStatusFilter(_ filter: OrderStatusFilter) {
        if selectedRole == .buying {
            buyingStatusFilter = filter
        } else {
            sellingStatusFilter = filter
        }
    }

    func refresh(deps: AppDependencies) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        await fetchOrders(deps: deps)
    }

    func pullToRefresh(deps: AppDependencies) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await fetchOrders(deps: deps)
    }

    func confirmReceipt(orderId: String, deps: AppDependencies) async {
        confirmingOrderId = orderId
        defer { confirmingOrderId = nil }
        switch await deps.orderRepository.confirmReceipt(orderId: orderId) {
        case .success:
            await fetchOrders(deps: deps)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func fetchOrders(deps: AppDependencies) async {
        async let buying = deps.orderRepository.getBuyingOrders()
        async let selling = deps.orderRepository.getSellingOrders()
        let buyingResult = await buying
        let sellingResult = await selling
        switch buyingResult {
        case .success(let orders):
            buyingOrders = orders
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        if case .success(let orders) = sellingResult {
            sellingOrders = orders
        }
    }
}
