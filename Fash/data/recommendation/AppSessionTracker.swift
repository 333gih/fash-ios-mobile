import Foundation

/// One `app_open` feed event per foreground session — Android [AppSessionTracker].
@MainActor
final class AppSessionTracker {
    static let shared = AppSessionTracker()

    private var reportedThisForegroundSession = false
    private var debounceTask: Task<Void, Never>?

    private static let debounceMs: UInt64 = 500

    func onSceneBecameActive(deps: AppDependencies) {
        guard !reportedThisForegroundSession else { return }
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(Self.debounceMs))
            guard !Task.isCancelled, !reportedThisForegroundSession else { return }
            reportedThisForegroundSession = true
            deps.feedEventReporter.appOpen()
        }
    }

    func onSceneBackground() {
        debounceTask?.cancel()
        debounceTask = nil
        reportedThisForegroundSession = false
    }
}
