import Foundation

enum OrderDetailBusyAction: Equatable {
    case none
    case checkIn
    case acknowledgeCash
    case reportNoShow
    case confirmHandoff
    case ship
    case confirmReceipt
    case submitReview
    case openDispute
    case submitEvidence
    case cancelOrder
}
