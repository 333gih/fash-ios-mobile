import Foundation

struct FeedEventPayload: Equatable {
    let listingId: String
    let surface: String
    let eventType: String
    let position: Int
    let dwellMs: Int?
    let experimentId: String?
}

/// Batches feed impressions/clicks — Android [FeedEventReporter].
///
/// Server accepts events asynchronously (`POST …/feed-events` returns quickly); we flush on a
/// debounced timer so impressions are not held until 20 items, and high-intent events still flush immediately.
final class FeedEventReporter: @unchecked Sendable {
    private let repository: RecommendationRepository
    private let sessionIdProvider: @Sendable () -> String
    private let publicBrowse: @Sendable () -> Bool
    private var pending: [FeedEventPayload] = []
    private let lock = NSLock()
    private var debouncedFlushTask: Task<Void, Never>?

    /// Impression/dwell batches flush on this interval (server ingest is async).
    private static let debouncedFlushSeconds: UInt64 = 4

    init(
        repository: RecommendationRepository,
        sessionIdProvider: @escaping @Sendable () -> String,
        publicBrowse: @escaping @Sendable () -> Bool
    ) {
        self.repository = repository
        self.sessionIdProvider = sessionIdProvider
        self.publicBrowse = publicBrowse
    }

    func impression(listingId: String, surface: String, position: Int = 0, dwellMs: Int? = nil) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "impression", position: position, dwellMs: dwellMs))
    }

    func click(listingId: String, surface: String, position: Int = 0) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "click", position: position))
        flush()
    }

    func previewOpen(listingId: String, surface: String, position: Int = 0) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "preview_open", position: position))
        flush()
    }

    func previewDismiss(listingId: String, surface: String, position: Int = 0, dwellMs: Int) {
        guard dwellMs > 0 else { return }
        enqueue(payload(listingId: listingId, surface: surface, eventType: "preview_dismiss", position: position, dwellMs: dwellMs))
        flush()
    }

    func previewDetail(listingId: String, surface: String, position: Int = 0) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "preview_detail", position: position))
        flush()
    }

    func dwell(listingId: String, surface: String, position: Int = 0, dwellMs: Int) {
        guard dwellMs > 0 else { return }
        enqueue(payload(listingId: listingId, surface: surface, eventType: "dwell", position: position, dwellMs: dwellMs))
    }

    func save(listingId: String, surface: String, position: Int = 0) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "save", position: position))
        flush()
    }

    func like(listingId: String, surface: String, position: Int = 0) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "like", position: position))
        flush()
    }

    func share(listingId: String, surface: String, position: Int = 0) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "share", position: position))
        flush()
    }

    func chatInitiate(listingId: String, surface: String, position: Int = 0) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "chat_initiate", position: position))
        flush()
    }

    func followSeller(listingId: String, surface: String, position: Int = 0) {
        enqueue(payload(listingId: listingId, surface: surface, eventType: "follow_seller", position: position))
        flush()
    }

    func appOpen() {
        enqueue(payload(
            listingId: FeedSurfaces.sessionSentinelListingId,
            surface: FeedSurfaces.appOpen,
            eventType: "click"
        ))
        flush()
    }

    func notificationOpen(listingId: String? = nil, scenarioId: String? = nil) {
        let trimmedListing = listingId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let resolvedListingId = trimmedListing.isEmpty ? FeedSurfaces.sessionSentinelListingId : trimmedListing
        let trimmedScenario = scenarioId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let experimentId = trimmedScenario.isEmpty ? nil : trimmedScenario
        enqueue(payload(
            listingId: resolvedListingId,
            surface: FeedSurfaces.notificationOpen,
            eventType: "click",
            experimentId: experimentId
        ))
        flush()
    }

    private func payload(
        listingId: String,
        surface: String,
        eventType: String,
        position: Int = 0,
        dwellMs: Int? = nil,
        experimentId: String? = nil
    ) -> FeedEventPayload {
        FeedEventPayload(
            listingId: listingId,
            surface: surface,
            eventType: eventType,
            position: position,
            dwellMs: dwellMs,
            experimentId: experimentId
        )
    }

    func clearPending() {
        cancelDebouncedFlush()
        lock.lock()
        pending.removeAll()
        lock.unlock()
    }

    func flush() {
        cancelDebouncedFlush()
        lock.lock()
        guard !pending.isEmpty else {
            lock.unlock()
            return
        }
        let batch = pending
        pending.removeAll()
        let session = sessionIdProvider()
        let guest = publicBrowse()
        lock.unlock()

        Task {
            _ = await repository.recordFeedEvents(publicBrowse: guest, sessionId: session, events: batch)
        }
    }

    private func enqueue(_ event: FeedEventPayload) {
        lock.lock()
        pending.append(event)
        let shouldFlush = pending.count >= 20
        lock.unlock()
        if shouldFlush {
            flush()
        } else {
            scheduleDebouncedFlush()
        }
    }

    private func scheduleDebouncedFlush() {
        debouncedFlushTask?.cancel()
        debouncedFlushTask = Task {
            try? await Task.sleep(for: .seconds(Self.debouncedFlushSeconds))
            guard !Task.isCancelled else { return }
            flush()
        }
    }

    private func cancelDebouncedFlush() {
        debouncedFlushTask?.cancel()
        debouncedFlushTask = nil
    }
}
