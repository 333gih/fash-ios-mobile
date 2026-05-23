import Foundation

final class FcmTokenRegistrar {
    private let authRepository: AuthRepository
    private let sessionStore: AuthSessionStore

    init(authRepository: AuthRepository, sessionStore: AuthSessionStore) {
        self.authRepository = authRepository
        self.sessionStore = sessionStore
    }

    func registerDeviceToken(_ token: String) async {
        guard let session = sessionStore.read() else { return }
        _ = await authRepository.registerFcm(accessToken: session.accessToken, token: token)
    }
}
