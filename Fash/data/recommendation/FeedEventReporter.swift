import Foundation

struct FeedEventPayload: Equatable {
    let listingId: String
    let surface: String
    let eventType: String
    let position: Int
    let dwellMs: Int?
}

/// Batches feed impressions/clicks — Android [FeedEventReporter].
final class FeedEventReporter: @unchecked Sendable {
    private let repository: RecommendationRepository
    private let sessionIdProvider: @Sendable () -> String
    private let publicBrowse: @Sendable () -> Bool
    private var pending: [FeedEventPayload] = []
    private let lock = NSLock()

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
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "impression", position: position, dwellMs: dwellMs))
    }

    func click(listingId: String, surface: String, position: Int = 0) {
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "click", position: position, dwellMs: nil))
        flush()
    }

    func previewOpen(listingId: String, surface: String, position: Int = 0) {
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "preview_open", position: position, dwellMs: nil))
        flush()
    }

    func previewDismiss(listingId: String, surface: String, position: Int = 0, dwellMs: Int) {
        guard dwellMs > 0 else { return }
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "preview_dismiss", position: position, dwellMs: dwellMs))
        flush()
    }

    func previewDetail(listingId: String, surface: String, position: Int = 0) {
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "preview_detail", position: position, dwellMs: nil))
        flush()
    }

    func dwell(listingId: String, surface: String, position: Int = 0, dwellMs: Int) {
        guard dwellMs > 0 else { return }
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "dwell", position: position, dwellMs: dwellMs))
    }

    func save(listingId: String, surface: String, position: Int = 0) {
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "save", position: position, dwellMs: nil))
        flush()
    }

    func like(listingId: String, surface: String, position: Int = 0) {
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "like", position: position, dwellMs: nil))
        flush()
    }

    func share(listingId: String, surface: String, position: Int = 0) {
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "share", position: position, dwellMs: nil))
        flush()
    }

    func chatInitiate(listingId: String, surface: String, position: Int = 0) {
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "chat_initiate", position: position, dwellMs: nil))
        flush()
    }

    func followSeller(listingId: String, surface: String, position: Int = 0) {
        enqueue(FeedEventPayload(listingId: listingId, surface: surface, eventType: "follow_seller", position: position, dwellMs: nil))
        flush()
    }

    func clearPending() {
        lock.lock()
        pending.removeAll()
        lock.unlock()
    }

    func flush() {
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
        if shouldFlush { flush() }
    }
}
