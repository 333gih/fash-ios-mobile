import Foundation

/// Parsed error from FASH HTTP APIs (core-service, auth-service, Kong gateway).
struct ServiceError: Equatable {
    static let rateLimitCodes: Set<String> = [
        "RATE_LIMIT_EXCEEDED",
        "OTP_REQUEST_LIMIT",
        "OTP_LOCKED",
        "TOO_MANY_PAYMENT_ATTEMPTS",
    ]

    let httpCode: Int
    let code: String?
    let message: String
    let retryAfterSeconds: Int?

    var isRateLimited: Bool {
        httpCode == 429 || (code.map { Self.rateLimitCodes.contains($0) } ?? false)
    }
}

/// Port of Android `CoreServiceErrors` (data.http).
enum CoreServiceErrors {
    static func parse(data: Data, statusCode: Int, retryAfterHeader: String? = nil) -> ServiceError {
        let retryAfter = parseRetryAfter(retryAfterHeader)
        if let json = try? HttpJson.dictionary(data) {
            let code = parseCodeField(json, httpCode: statusCode)
            if let err = json["error"] as? String, !err.isEmpty {
                return ServiceError(
                    httpCode: statusCode,
                    code: normalizedCode(code, httpCode: statusCode),
                    message: err,
                    retryAfterSeconds: retryAfter
                )
            }
            if let msg = json["message"] as? String, !msg.isEmpty {
                return ServiceError(
                    httpCode: statusCode,
                    code: normalizedCode(code, httpCode: statusCode),
                    message: msg,
                    retryAfterSeconds: retryAfter
                )
            }
        }
        let fallback = fallbackMessage(statusCode)
        return ServiceError(
            httpCode: statusCode,
            code: normalizedCode(nil, httpCode: statusCode),
            message: fallback,
            retryAfterSeconds: retryAfter
        )
    }

    static func parseMessage(data: Data, statusCode: Int) -> String {
        parse(data: data, statusCode: statusCode).message
    }

    static func localizedMessage(_ error: ServiceError, otpContext: Bool = false) -> String {
        guard error.isRateLimited else { return error.message }
        if otpContext, let retry = error.retryAfterSeconds, retry > 0 {
            return L10n.errorRateLimitOtpWait(retry)
        }
        if otpContext {
            return L10n.errorRateLimitOtp
        }
        if let retry = error.retryAfterSeconds, retry > 0 {
            return L10n.errorRateLimitWait(retry)
        }
        return L10n.errorRateLimitGeneric
    }

    private static func parseCodeField(_ json: [String: Any], httpCode: Int) -> String? {
        guard let raw = json["code"] else { return nil }
        if let s = raw as? String {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let n = raw as? NSNumber, n.intValue == 429 || httpCode == 429 {
            return "RATE_LIMIT_EXCEEDED"
        }
        return nil
    }

    private static func normalizedCode(_ parsed: String?, httpCode: Int) -> String? {
        if let parsed { return parsed }
        if httpCode == 429 { return "RATE_LIMIT_EXCEEDED" }
        return nil
    }

    private static func parseRetryAfter(_ header: String?) -> Int? {
        let raw = header?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return nil }
        if let n = Int(raw), n > 0 { return n }
        if let n = Int64(raw), n > 0 { return min(Int(n), Int.max) }
        return nil
    }

    private static func fallbackMessage(_ statusCode: Int) -> String {
        switch statusCode {
        case 400: return L10n.errorHttpBadRequest
        case 401: return L10n.errorHttpUnauthorized
        case 403: return L10n.errorHttpForbidden
        case 404: return L10n.errorHttpNotFound
        case 409: return L10n.errorHttpConflict
        case 429: return L10n.errorRateLimitGeneric
        case 500: return L10n.errorHttpServer
        default: return L10n.errorHttpStatus(statusCode)
        }
    }
}

struct CoreServiceHttpException: Error, LocalizedError {
    let statusCode: Int
    let message: String
    let serviceError: ServiceError

    init(statusCode: Int, message: String, serviceError: ServiceError? = nil) {
        self.statusCode = statusCode
        self.message = message
        self.serviceError = serviceError ?? ServiceError(httpCode: statusCode, code: statusCode == 429 ? "RATE_LIMIT_EXCEEDED" : nil, message: message, retryAfterSeconds: nil)
    }

    var errorCode: String? { serviceError.code }
    var isRateLimited: Bool { serviceError.isRateLimited }
    var retryAfterSeconds: Int? { serviceError.retryAfterSeconds }
    var errorDescription: String? { CoreServiceErrors.localizedMessage(serviceError) }
}
