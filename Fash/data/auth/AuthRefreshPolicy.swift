import Foundation

/// Port of Android [AuthRefreshPolicy] — keeps session on transient network failures.
enum AuthRefreshPolicy {
    private static let definitiveAuthFailureCodes: Set<Int> = [400, 401, 403]

    static func isTransientRefreshFailure(_ error: Error) -> Bool {
        var current: Error? = error
        while let e = current {
            if e is DecodingError { return true }
            if let urlError = e as? URLError {
                switch urlError.code {
                case .timedOut:
                    return false
                case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
                     .cannotFindHost, .dnsLookupFailed, .dataNotAllowed:
                    return true
                default:
                    break
                }
            }
            if let http = e as? CoreServiceHttpException {
                return !definitiveAuthFailureCodes.contains(http.statusCode)
            }
            current = (e as NSError).userInfo[NSUnderlyingErrorKey] as? Error
        }
        return true
    }
}
