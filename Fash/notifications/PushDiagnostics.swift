import Foundation
import os

/// Release-visible push logs (Console.app / TestFlight diagnostics).
enum PushDiagnostics {
    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.pc.fash-ios-mobile",
        category: "Push"
    )

    static func info(_ message: String) {
        log.info("\(message, privacy: .public)")
    }

    static func warning(_ message: String) {
        log.warning("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        log.error("\(message, privacy: .public)")
    }

    /// Logs token prefix, length, and inferred kind (FCM vs raw APNs hex) for TestFlight diagnostics.
    static func logTokenMetadata(_ token: String, context: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            warning("\(context): empty token")
            return
        }
        let prefix = trimmed.count > 8 ? String(trimmed.prefix(8)) + "…" : trimmed
        let kind: String
        if looksLikeFCMRegistration(trimmed) {
            kind = "fcm_registration"
        } else if looksLikeRawAPNSHex(trimmed) {
            kind = "raw_apns_hex"
        } else {
            kind = "unknown"
        }
        info("\(context): token_prefix=\(prefix) length=\(trimmed.count) kind=\(kind)")
    }

    static func looksLikeRawAPNSHex(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 64 && trimmed.allSatisfy(\.isHexDigit)
    }

    static func looksLikeFCMRegistration(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 100, trimmed.contains(":") { return true }
        return trimmed.count >= 140
    }
}
