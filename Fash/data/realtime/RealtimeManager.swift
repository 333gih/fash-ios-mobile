import Foundation

/// WebSocket realtime — Android [RealtimeManager].
final class RealtimeManager: @unchecked Sendable {
    private let baseURL: String
    private let sessionStore: AuthSessionStore
    private let authRepository: AuthRepository
    private let socketLock = NSLock()
    private var webSocketTask: URLSessionWebSocketTask?

    init(baseURL: String, sessionStore: AuthSessionStore, authRepository: AuthRepository) {
        self.baseURL = baseURL
        self.sessionStore = sessionStore
        self.authRepository = authRepository
    }

    func connect(onEvent: (@MainActor (String) -> Void)? = nil) async {
        guard let session = sessionStore.read(), !session.accessToken.isEmpty else { return }
        disconnect()
        let wsBase = baseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(wsBase)/ws?token=\(session.accessToken)") else { return }
        let task = URLSession.shared.webSocketTask(with: url)
        socketLock.lock()
        webSocketTask = task
        socketLock.unlock()
        task.resume()
        receiveLoop(onEvent: onEvent)
    }

    func disconnect() {
        socketLock.lock()
        let task = webSocketTask
        webSocketTask = nil
        socketLock.unlock()
        task?.cancel(with: .goingAway, reason: nil)
    }

    private func receiveLoop(onEvent: (@MainActor (String) -> Void)?) {
        socketLock.lock()
        let task = webSocketTask
        socketLock.unlock()
        guard let task else { return }

        task.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message, let onEvent {
                    Task { @MainActor in onEvent(text) }
                }
                self?.receiveLoop(onEvent: onEvent)
            case .failure:
                break
            }
        }
    }
}
