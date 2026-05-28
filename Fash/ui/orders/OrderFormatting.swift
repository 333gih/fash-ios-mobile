import Foundation

enum OrderFormatting {
    static func normalizeStatus(_ raw: String) -> String {
        switch raw.lowercased().trimmingCharacters(in: .whitespaces) {
        case "delivering", "shipped", "shipping": return "in_transit"
        case "completed": return "delivered_confirmed"
        case "pending": return "payment_pending"
        default: return raw.lowercased().trimmingCharacters(in: .whitespaces)
        }
    }

    static func statusLabel(_ status: String) -> String {
        switch normalizeStatus(status) {
        case "payment_pending": return L10n.orderStatusPaymentPending
        case "payment_held": return L10n.orderStatusPaymentHeld
        case "in_transit": return L10n.orderStatusInTransit
        case "delivered_confirmed": return L10n.orderStatusDeliveredConfirmed
        case "cancelled": return L10n.orderStatusCancelled
        case "disputed": return L10n.orderStatusDisputed
        case "cash_meetup_open": return L10n.orderStatusCashMeetupOpen
        case "fulfillment_pending": return L10n.orderStatusFulfillmentPending
        default:
            let trimmed = status.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? L10n.orderStatusUnknown : trimmed
        }
    }

    static func formatShortDate(_ iso: String) -> String {
        let trimmed = iso.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        let normalized = trimmed.contains("T") ? trimmed : trimmed.replacingOccurrences(of: " ", with: "T")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: normalized)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: normalized)
        }
        guard let date else { return String(trimmed.prefix(16)) }
        let out = DateFormatter()
        out.locale = AppLocale.locale
        out.dateStyle = .medium
        out.timeStyle = .short
        return out.string(from: date)
    }
}
