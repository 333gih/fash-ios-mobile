#if canImport(Sentry)
import Sentry

/// Initializes Sentry when `SENTRY_DSN` is set in env and the Sentry SPM package is linked.
enum SentryBootstrap {
    static func configureIfNeeded() {
        let dsn = BuildConfig.sentryDsn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dsn.isEmpty else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = AppEnvironment.environmentName
            options.tracesSampleRate = 0.2
            options.enableAutoSessionTracking = true
            options.enableAppHangTracking = true
            // Default 2s flags SwiftUI Attribute Graph updates (AG::Subgraph::update) on older phones.
            options.appHangTimeoutInterval = 4
            // Capture application 5xx, not gateway/maintenance 502–504 (those flood during outages).
            options.enableCaptureFailedRequests = true
            options.failedRequestStatusCodes = [
                HttpStatusCodeRange(min: 500, max: 501),
                HttpStatusCodeRange(min: 505, max: 599),
            ]
            options.beforeSend = { event in
                if Self.shouldDropUnavailableHttpEvent(event) { return nil }
                return event
            }
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "\(version) (\(build))"
            }
        }
    }

    /// HTTPClientError 502/503/504 still attached as children of app-hang events on older SDK paths.
    private static func shouldDropUnavailableHttpEvent(_ event: Event) -> Bool {
        let type = event.exceptions?.first?.type ?? ""
        guard type == "HTTPClientError" || type.contains("HTTP") else { return false }
        if let status = httpStatusCode(from: event), CoreHttpRetry.isUnavailable(status) {
            return true
        }
        let value = (event.exceptions?.first?.value ?? "").lowercased()
        return value.contains("503") || value.contains("502") || value.contains("504")
    }

    private static func httpStatusCode(from event: Event) -> Int? {
        if let response = event.context?["response"] as? [String: Any] {
            if let n = response["status_code"] as? NSNumber { return n.intValue }
            if let n = response["status_code"] as? Int { return n }
        }
        if let extra = event.extra?["statusCode"] as? NSNumber { return extra.intValue }
        return nil
    }
}
#endif
