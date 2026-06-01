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
}
