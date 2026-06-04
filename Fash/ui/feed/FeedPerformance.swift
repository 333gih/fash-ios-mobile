import Foundation

/// Lightweight feed profiling — enable with `FEED_PERF_LOG=1` in scheme environment.
enum FeedPerformance {
    private static let enabled = ProcessInfo.processInfo.environment["FEED_PERF_LOG"] == "1"

    static func measure<T>(_ label: String, _ work: () async throws -> T) async rethrows -> T {
        guard enabled else { return try await work() }
        let start = Date()
        let result = try await work()
        let ms = Date().timeIntervalSince(start) * 1_000
        print("[FeedPerf] \(label): \(String(format: "%.1f", ms))ms")
        return result
    }

    static func log(_ message: String) {
        guard enabled else { return }
        print("[FeedPerf] \(message)")
    }
}
