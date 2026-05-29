import Foundation

struct OrderCancelledChatPayload: Equatable {
    let orderId: String
    let reasonCode: String
    let cancelledBy: String
    let amountVnd: Int64
    let reasonNote: String

    static let orderIdPrefix = "FASH_ORDER_CANCELLED_ORDER_ID="

    static func parse(messageType: String, fullText: String) -> OrderCancelledChatPayload? {
        if messageType.lowercased() == "order_cancelled" {
            return parseJson(fullText)
        }
        return parseLegacy(fullText)
    }

    private static func parseJson(_ fullText: String) -> OrderCancelledChatPayload? {
        let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8),
              let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let orderId = stringField(o, "order_id", "orderId")
        guard !orderId.isEmpty else { return nil }
        return OrderCancelledChatPayload(
            orderId: orderId,
            reasonCode: stringField(o, "reason_code", "reasonCode").lowercased(),
            cancelledBy: stringField(o, "cancelled_by", "cancelledBy", default: "buyer").lowercased(),
            amountVnd: intField(o, "amount_vnd", "amountVnd"),
            reasonNote: stringField(o, "reason_note", "reasonNote")
        )
    }

    private static func parseLegacy(_ fullText: String) -> OrderCancelledChatPayload? {
        let firstLine = fullText.lineSequence().first.map(String.init) ?? ""
        guard firstLine.hasPrefix(orderIdPrefix) else { return nil }
        var orderId = String(firstLine.dropFirst(orderIdPrefix.count))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if orderId.hasSuffix("...") {
            orderId = String(orderId.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !orderId.isEmpty else { return nil }
        let note = fullText.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            .dropFirst()
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return OrderCancelledChatPayload(
            orderId: orderId,
            reasonCode: "changed_mind",
            cancelledBy: "buyer",
            amountVnd: 0,
            reasonNote: note
        )
    }

    private static func stringField(_ o: [String: Any], _ keys: String..., default defaultValue: String = "") -> String {
        for key in keys {
            if let s = o[key] as? String {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { return t }
            }
        }
        return defaultValue
    }

    private static func intField(_ o: [String: Any], _ keys: String...) -> Int64 {
        for key in keys {
            if let n = o[key] as? Int64 { return n }
            if let n = o[key] as? Int { return Int64(n) }
            if let n = o[key] as? Double { return Int64(n) }
            if let s = o[key] as? String, let n = Int64(s) { return n }
        }
        return 0
    }
}

func isOrderCancelledChatMessage(messageType: String, fullText: String) -> Bool {
    messageType.lowercased() == "order_cancelled"
        || fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            .hasPrefix(OrderCancelledChatPayload.orderIdPrefix)
}
