import Foundation

/// Tracks home/profile tab opens with dwell — Android [UxTabTracker].
final class UxTabTracker: @unchecked Sendable {
    private let repository: RecommendationRepository
    private let guestBrowse: @Sendable () -> Bool
    private var pending: [UxEventPayload] = []
    private var activeScope: String?
    private var activeTabKey: String?
    private var openedAt: Date?
    private let lock = NSLock()

    init(repository: RecommendationRepository, guestBrowse: @escaping @Sendable () -> Bool) {
        self.repository = repository
        self.guestBrowse = guestBrowse
    }

    func onTabOpened(scope: String, tabKey: String) {
        guard !guestBrowse() else { return }
        closeActiveTab()
        activeScope = scope
        activeTabKey = tabKey
        openedAt = Date()
        enqueue(UxEventPayload(scope: scope, tabKey: tabKey, clientHour: UxPersonalizationLocalStore.currentClientHour, dwellMs: nil))
    }

    func closeActiveTab() {
        guard let scope = activeScope, let tabKey = activeTabKey, let openedAt else { return }
        let dwellMs = Int(Date().timeIntervalSince(openedAt) * 1_000)
        if dwellMs >= 800 {
            enqueue(UxEventPayload(scope: scope, tabKey: tabKey, clientHour: UxPersonalizationLocalStore.currentClientHour, dwellMs: dwellMs))
        }
        activeScope = nil
        activeTabKey = nil
        self.openedAt = nil
    }

    func flush() {
        lock.lock()
        guard !pending.isEmpty, !guestBrowse() else {
            pending.removeAll()
            lock.unlock()
            return
        }
        let batch = pending
        pending.removeAll()
        lock.unlock()
        Task { _ = await repository.recordUxEvents(events: batch) }
    }

    private func enqueue(_ event: UxEventPayload) {
        lock.lock()
        pending.append(event)
        let shouldFlush = pending.count >= 20
        lock.unlock()
        if shouldFlush { flush() }
    }
}
