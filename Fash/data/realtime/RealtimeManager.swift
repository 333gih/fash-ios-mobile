import Foundation

/// WebSocket realtime (Android [RealtimeManager]) — connect after login on Mac builds.
final class RealtimeManager {
    private let baseURL: String
    private let sessionStore: AuthSessionStore
    private let authRepository: AuthRepository

    init(baseURL: String, sessionStore: AuthSessionStore, authRepository: AuthRepository) {
        self.baseURL = baseURL
        self.sessionStore = sessionStore
        self.authRepository = authRepository
    }

    func connect() async {
        // Port WebSocket handshake from Android RealtimeManager.kt
    }
}
