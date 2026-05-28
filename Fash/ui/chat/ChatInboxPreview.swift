import Foundation

/// Inbox row subtitle — Android `ChatViewModel.conversationPreviewLine`.
enum ChatInboxPreview {
    static func conversationPreviewLine(_ item: ConversationItem, myUserId: String) -> String {
        let myId = myUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        let isSeller = !myId.isEmpty && item.sellerUserId == myId
        let isBuyer = !myId.isEmpty && item.buyerUserId == myId

        if item.pendingOfferAmountVnd > 0, isSeller {
            return L10n.chatInboxPreviewOfferPendingSeller(FeedPriceFormat.format(item.pendingOfferAmountVnd))
        }

        let isOfferRow = item.lastMessageType.lowercased() == "offer" || item.lastOfferAmountVnd > 0
        if isOfferRow {
            let amtStr: String = {
                if item.lastOfferAmountVnd > 0 {
                    return FeedPriceFormat.format(item.lastOfferAmountVnd)
                }
                let trimmed = item.lastMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? FeedPriceFormat.format(0) : trimmed
            }()
            if isBuyer, item.lastOfferFromBuyer {
                return L10n.chatInboxPreviewOfferYou(amtStr)
            }
            if isBuyer, !item.lastOfferFromBuyer {
                return L10n.chatInboxPreviewOfferFromSeller(amtStr)
            }
            if isSeller, item.lastOfferFromBuyer {
                return L10n.chatInboxPreviewOfferFromBuyer(amtStr)
            }
            return L10n.chatInboxPreviewOfferGeneric(amtStr)
        }

        let rawLast = item.lastMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastType = item.lastMessageType.trimmingCharacters(in: .whitespacesAndNewlines)
        if isOrderCancelledChatMessage(type: lastType, fullText: rawLast)
            || lastType.lowercased() == "order_cancelled"
            || rawLast == L10n.chatInboxPreviewOrderCancelledShort {
            if isSeller {
                return L10n.chatInboxPreviewOrderCancelledSeller
            }
            return orderCancelledChatPreviewText(rawLast) ?? L10n.chatInboxPreviewOrderCancelledShort
        }

        if rawLast.isEmpty {
            return L10n.chatInboxPreviewPlaceholder
        }
        return rawLast
    }

    private static func isOrderCancelledChatMessage(type: String, fullText: String) -> Bool {
        type.lowercased() == "order_cancelled"
            || fullText.trimmingCharacters(in: .whitespacesAndNewlines)
                .hasPrefix(OrderCancelledChatPayload.orderIdPrefix)
    }

    private static func orderCancelledChatPreviewText(_ fullText: String) -> String? {
        guard fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            .hasPrefix(OrderCancelledChatPayload.orderIdPrefix) else { return nil }
        let rest = fullText.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            .dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return rest.isEmpty ? nil : rest
    }
}

private enum OrderCancelledChatPayload {
    static let orderIdPrefix = "FASH_ORDER_CANCELLED_ORDER_ID="
}
