import Foundation

/// WebSocket realtime — Android [RealtimeManager].
final class RealtimeManager {
    private let baseURL: String
    private let sessionStore: AuthSessionStore
    private let authRepository: AuthRepository
    private var webSocketTask: URLSessionWebSocketTask?

    init(baseURL: String, sessionStore: AuthSessionStore, authRepository: AuthRepository) {
        self.baseURL = baseURL
        self.sessionStore = sessionStore
        self.authRepository = authRepository
    }

    func connect(onEvent: ((String) -> Void)? = nil) async {
        guard let session = sessionStore.read(), !session.accessToken.isEmpty else { return }
        disconnect()
        let wsBase = baseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(wsBase)/ws?token=\(session.accessToken)") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveLoop(onEvent: onEvent)
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    private func receiveLoop(onEvent: ((String) -> Void)?) {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message { onEvent?(text) }
                self?.receiveLoop(onEvent: onEvent)
            case .failure:
                break
            }
        }
    }
}
