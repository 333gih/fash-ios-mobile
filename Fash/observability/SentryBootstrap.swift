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
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "\(version) (\(build))"
            }
        }
    }
}
#endif
