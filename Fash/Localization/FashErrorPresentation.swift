import Foundation

/// Maps errors to user-facing copy that respects in-app locale (L10n), not only system locale.
enum FashErrorPresentation {
    static func userMessage(for error: Error, otpContext: Bool = false) -> String {
        if let http = error as? CoreServiceHttpException {
            return CoreServiceErrors.localizedMessage(http.serviceError, otpContext: otpContext)
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return L10n.errorNetworkUnavailable
            default:
                break
            }
        }
        let desc = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if desc.isEmpty { return L10n.errorGeneric }
        if desc == "Session expired. Please sign in again." { return L10n.sessionExpiredMessage }
        return desc
    }
}
