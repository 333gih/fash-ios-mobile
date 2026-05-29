import Foundation

/// Chat-specific error copy — Android `ChatDetailViewModel.mapOfferError` / send / check-in helpers.
enum ChatErrorPresentation {
    static func mapOfferError(_ error: Error, listedPriceVnd: Int64 = 0) -> String {
        let http = error as? CoreServiceHttpException
        let msg = errorMessageText(http, error)
        let status = http?.statusCode ?? 0
        let code = http?.errorCode ?? ""

        if containsCode(msg, code, "OFFER_LIMIT_REACHED") {
            return L10n.chatErrorOfferLimit(BusinessFlowConfig.maxOffersPerConversation)
        }
        if containsCode(msg, code, "PENDING_OFFER") || msg.localizedCaseInsensitiveContains("pending offer") {
            return L10n.chatErrorPendingOffer
        }
        if containsCode(msg, code, "CONVERSATION_CLOSED") {
            return L10n.chatErrorConversationClosed
        }
        if containsCode(msg, code, "CONVERSATION_ORDER_EXISTS") {
            return L10n.chatErrorConversationOrderExists
        }
        if status == 409 {
            return L10n.chatErrorOrderExists
        }
        if status == 403 || containsCode(msg, code, "FORBIDDEN") {
            return L10n.chatErrorForbidden
        }
        if status == 404 || containsCode(msg, code, "NOT_FOUND") {
            return L10n.chatErrorNotFound
        }
        if status == 400 || containsCode(msg, code, "VALIDATION") {
            if listedPriceVnd > 0 {
                return L10n.chatOfferMustBeBelowListed(FeedPriceFormat.format(listedPriceVnd))
            }
            return L10n.chatOfferError
        }
        if !msg.isEmpty { return msg }
        return L10n.chatOfferError
    }

    static func mapOfferActionError(_ error: Error) -> String {
        let msg = errorMessageText(error as? CoreServiceHttpException, error)
        return msg.isEmpty ? L10n.chatOfferError : msg
    }

    static func mapSendMessageError(_ error: Error) -> String {
        let http = error as? CoreServiceHttpException
        let msg = errorMessageText(http, error)
        if let status = http?.statusCode, [502, 503, 504].contains(status) {
            return L10n.chatSendErrorGateway(status)
        }
        if let match = msg.range(of: #"\b(502|503|504)\b"#, options: .regularExpression) {
            let code = Int(msg[match]) ?? 502
            return L10n.chatSendErrorGateway(code)
        }
        return msg.isEmpty ? L10n.chatSendError : msg
    }

    static func mapMeetingCheckInError(_ error: Error) -> String {
        let msg = errorMessageText(error as? CoreServiceHttpException, error)
        if msg.localizedCaseInsensitiveContains("MEETING_CHECK_IN_WINDOW") {
            return L10n.chatMeetingCheckInWindowError
        }
        if msg.contains("400"),
           msg.localizedCaseInsensitiveContains("MEETING_CHECK_IN") || msg.localizedCaseInsensitiveContains("check-in") || msg.localizedCaseInsensitiveContains("check_in"),
           msg.localizedCaseInsensitiveContains("WINDOW") {
            return L10n.chatMeetingCheckInWindowError
        }
        if msg.contains("400"),
           msg.localizedCaseInsensitiveContains("validation") || msg.localizedCaseInsensitiveContains("VALIDATION") {
            return L10n.meetingCheckInRequiresOnMyWay
        }
        return msg.isEmpty ? L10n.chatMeetingError : msg
    }

    static func validateBuyerOffer(amountVnd: Int64, listedPriceVnd: Int64) -> String? {
        if amountVnd < 1000 { return L10n.chatCounterOfferMin }
        if listedPriceVnd > 0, amountVnd >= listedPriceVnd {
            return L10n.chatOfferMustBeBelowListed(FeedPriceFormat.format(listedPriceVnd))
        }
        return nil
    }

    static func validateCounterOffer(amountVnd: Int64, buyerOfferVnd: Int64, listedPriceVnd: Int64) -> String? {
        if amountVnd < 1000 { return L10n.chatCounterOfferMin }
        if buyerOfferVnd > 0, amountVnd <= buyerOfferVnd {
            return L10n.chatCounterMustBeAboveBuyer(FeedPriceFormat.format(buyerOfferVnd))
        }
        if listedPriceVnd > 0, amountVnd >= listedPriceVnd {
            return L10n.chatOfferMustBeBelowListed(FeedPriceFormat.format(listedPriceVnd))
        }
        return nil
    }

    private static func errorMessageText(_ http: CoreServiceHttpException?, _ error: Error) -> String {
        if let http {
            let localized = FashErrorPresentation.userMessage(for: http)
            if !localized.isEmpty { return localized }
        }
        return error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsCode(_ message: String, _ code: String, _ token: String) -> Bool {
        message.localizedCaseInsensitiveContains(token) || code.localizedCaseInsensitiveContains(token)
    }
}
