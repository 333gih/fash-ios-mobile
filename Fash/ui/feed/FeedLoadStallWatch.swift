import Foundation

/// Fires when a tab’s first-page load stays empty past `FeedLoadStallPolicy.timeoutSeconds`.
@MainActor
final class FeedLoadStallWatch {
    private var epochs: [String: UInt] = [:]
    private var tasks: [String: Task<Void, Never>] = [:]

    func schedule(
        key: String,
        isStillPending: @escaping @MainActor () -> Bool,
        onStalled: @escaping @MainActor () -> Void
    ) {
        tasks[key]?.cancel()
        let epoch = (epochs[key] ?? 0) + 1
        epochs[key] = epoch
        tasks[key] = Task {
            try? await Task.sleep(for: .seconds(FeedLoadStallPolicy.timeoutSeconds))
            guard !Task.isCancelled else { return }
            guard epochs[key] == epoch else { return }
            guard isStillPending() else { return }
            onStalled()
        }
    }

    func cancel(key: String) {
        tasks[key]?.cancel()
        tasks[key] = nil
    }

    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
        epochs.removeAll()
    }
}
