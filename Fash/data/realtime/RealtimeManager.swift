import Foundation

enum RealtimeConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
}

/// WebSocket realtime — Android [RealtimeManager].
final class RealtimeManager: @unchecked Sendable {
    private let baseURL: String
    private let sessionStore: AuthSessionStore
    private let authRepository: AuthRepository

    private let lock = NSLock()
    private var state: RealtimeConnectionState = .disconnected
    private var intentionalDisconnect = false
    private var webSocketTask: URLSessionWebSocketTask?
    private var subscribedConversations = Set<String>()
    private var subscribedListings = Set<String>()
    private var pendingFrames: [[String: Any]] = []
    private var reconnectDelayMs = 2_000
    private var reconnectTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?

    private let listenerLock = NSLock()
    private var listeners: [UUID: @Sendable @MainActor (RealtimeEvent) -> Void] = [:]
    private var legacyHandler: (@MainActor (RealtimeEvent) -> Void)?

    init(baseURL: String, sessionStore: AuthSessionStore, authRepository: AuthRepository) {
        self.baseURL = baseURL
        self.sessionStore = sessionStore
        self.authRepository = authRepository
    }

    var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return state == .connected
    }

    func setEventHandler(_ handler: (@MainActor (RealtimeEvent) -> Void)?) {
        legacyHandler = handler
    }

    @discardableResult
    func addEventListener(_ listener: @escaping @MainActor (RealtimeEvent) -> Void) -> UUID {
        let id = UUID()
        listenerLock.lock()
        listeners[id] = listener
        listenerLock.unlock()
        return id
    }

    func removeEventListener(_ id: UUID) {
        listenerLock.lock()
        listeners.removeValue(forKey: id)
        listenerLock.unlock()
    }

    func connect() async {
        lock.lock()
        if state != .disconnected {
            lock.unlock()
            return
        }
        intentionalDisconnect = false
        lock.unlock()
        await openSocket()
    }

    func disconnect(clearSubscriptions: Bool = true) {
        intentionalDisconnect = true
        reconnectTask?.cancel()
        reconnectTask = nil
        receiveTask?.cancel()
        receiveTask = nil

        lock.lock()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        state = .disconnected
        if clearSubscriptions {
            subscribedConversations.removeAll()
            subscribedListings.removeAll()
            pendingFrames.removeAll()
        }
        lock.unlock()
    }

    func subscribeToConversation(_ conversationId: String) {
        let id = conversationId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        lock.lock()
        subscribedConversations.insert(id)
        lock.unlock()
        sendFrame(["type": "subscribe.conversation", "conversation_id": id])
    }

    func unsubscribeFromConversation(_ conversationId: String) {
        let id = conversationId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        lock.lock()
        subscribedConversations.remove(id)
        lock.unlock()
        sendFrame(["type": "unsubscribe.conversation", "conversation_id": id])
    }

    func subscribeToListing(_ listingId: String) {
        let id = listingId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        lock.lock()
        subscribedListings.insert(id)
        lock.unlock()
        sendFrame(["type": "subscribe.listing", "listing_id": id])
    }

    func unsubscribeFromListing(_ listingId: String) {
        let id = listingId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        lock.lock()
        subscribedListings.remove(id)
        lock.unlock()
        sendFrame(["type": "unsubscribe.listing", "listing_id": id])
    }

    func sendPing() {
        sendFrame(["type": "ping"])
    }

    func sendTypingStart(conversationId: String) {
        let id = conversationId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        sendFrame(["type": "typing.start", "conversation_id": id])
    }

    func sendTypingStop(conversationId: String) {
        let id = conversationId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        sendFrame(["type": "typing.stop", "conversation_id": id])
    }

    // MARK: - Private

    private func openSocket() async {
        guard let session = sessionStore.read(), !session.accessToken.isEmpty else { return }

        lock.lock()
        state = .connecting
        lock.unlock()

        let wsBase = baseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        var components = URLComponents(string: "\(wsBase)/ws")
        components?.queryItems = [
            URLQueryItem(name: "token", value: session.accessToken),
            URLQueryItem(name: "platform", value: "ios"),
        ]
        guard let url = components?.url else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.webSocketTask(with: request)
        lock.lock()
        webSocketTask = task
        lock.unlock()
        task.resume()
        startReceiveLoop(on: task)
    }

    private func startReceiveLoop(on task: URLSessionWebSocketTask) {
        receiveTask?.cancel()
        receiveTask = Task {
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    guard case .string(let text) = message else { continue }
                    guard let event = RealtimeEvent.parse(jsonText: text) else { continue }
                    if case .connected = event {
                        lock.lock()
                        state = .connected
                        reconnectDelayMs = 2_000
                        lock.unlock()
                        flushPendingOutbound()
                        resubscribeAll()
                    }
                    await emit(event)
                } catch {
                    lock.lock()
                    let shouldReconnect = !intentionalDisconnect
                    webSocketTask = nil
                    state = .disconnected
                    lock.unlock()
                    if shouldReconnect {
                        await emit(.disconnected(willReconnect: true))
                        scheduleReconnect(authFailure: false)
                    } else {
                        await emit(.disconnected(willReconnect: false))
                    }
                    break
                }
            }
        }
    }

    private func scheduleReconnect(authFailure: Bool) {
        reconnectTask?.cancel()
        let delay = reconnectDelayMs
        reconnectTask = Task {
            try? await Task.sleep(for: .milliseconds(delay))
            guard !Task.isCancelled else { return }
            lock.lock()
            let disconnected = state == .disconnected && !intentionalDisconnect
            lock.unlock()
            guard disconnected else { return }

            if authFailure {
                let stale = sessionStore.read()?.accessToken ?? ""
                let result = await AuthTokenRefreshCoordinator.refreshIfStillCurrent(
                    sessionStore: sessionStore,
                    authRepository: authRepository,
                    accessTokenWhenUnauthorized: stale
                )
                guard case .success = result else { return }
            }

            lock.lock()
            reconnectDelayMs = min(reconnectDelayMs * 2, 30_000)
            lock.unlock()
            await openSocket()
        }
    }

    private func resubscribeAll() {
        lock.lock()
        let conversations = subscribedConversations
        let listings = subscribedListings
        lock.unlock()
        for id in conversations {
            sendFrame(["type": "subscribe.conversation", "conversation_id": id], force: true)
        }
        for id in listings {
            sendFrame(["type": "subscribe.listing", "listing_id": id], force: true)
        }
    }

    private func flushPendingOutbound() {
        lock.lock()
        let batch = pendingFrames
        pendingFrames.removeAll()
        lock.unlock()
        for frame in batch {
            sendFrame(frame, force: true)
        }
    }

    private func sendFrame(_ body: [String: Any], force: Bool = false) {
        guard let data = try? JSONSerialization.data(withJSONObject: body),
              let text = String(data: data, encoding: .utf8) else { return }

        lock.lock()
        let connected = state == .connected
        let task = webSocketTask
        if !force && !connected {
            if pendingFrames.count < 64 {
                pendingFrames.append(body)
            }
            lock.unlock()
            return
        }
        lock.unlock()

        task?.send(.string(text)) { [weak self] error in
            if error != nil {
                self?.scheduleReconnect(authFailure: false)
            }
        }
    }

    @MainActor
    private func emit(_ event: RealtimeEvent) async {
        legacyHandler?(event)
        listenerLock.lock()
        let snapshot = listeners
        listenerLock.unlock()
        for handler in snapshot.values {
            handler(event)
        }
    }
}
