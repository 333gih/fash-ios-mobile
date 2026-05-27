import Foundation
import Security

struct AuthSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var tokenType: String
    var userId: String?
    var expiresInSeconds: Int64 = 0
    var isNewUser: Bool = false
    var unreadCount: Int64 = 0
}

/// Encrypted session storage (Android [AuthSessionStore]).
final class AuthSessionStore {
    private let key = "fash_auth_session"

    func read() -> AuthSession? {
        guard let data = KeychainHelper.load(key: key) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func save(_ session: AuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        KeychainHelper.save(data, key: key)
    }

    func clear() {
        KeychainHelper.delete(key: key)
    }
}

enum KeychainHelper {
    static func save(_ data: Data, key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
