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

    enum OrderRole: String, CaseIterable {
        case buying
        case selling
    }

    var activeOrders: [OrderItem] {
        selectedRole == .buying ? buyingOrders : sellingOrders
    }

    func refresh(deps: AppDependencies) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
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

    func pullToRefresh(deps: AppDependencies) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(deps: deps)
    }
}
