import Foundation

final class OrderCancelCoordinator {
    private let orderRepository: OrderRepository
    private let chatRepository: ChatRepository

    init(orderRepository: OrderRepository, chatRepository: ChatRepository) {
        self.orderRepository = orderRepository
        self.chatRepository = chatRepository
    }
}
