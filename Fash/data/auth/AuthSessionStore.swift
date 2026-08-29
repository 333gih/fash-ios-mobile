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
    /// UTC millis when this pair was issued (login / refresh). Used for proactive refresh.
    var issuedAtMillis: Int64 = 0
}

/// Encrypted session storage (Android [AuthSessionStore]).
final class AuthSessionStore {
    private let key = "fash_auth_session"

    func read() -> AuthSession? {
        guard let data = KeychainHelper.load(key: key) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func save(_ session: AuthSession) {
        var copy = session
        copy.issuedAtMillis = Int64(Date().timeIntervalSince1970 * 1000)
        guard let data = try? JSONEncoder().encode(copy) else { return }
        KeychainHelper.save(data, key: key)
    }

    func issuedAtMillis() -> Int64 {
        read()?.issuedAtMillis ?? 0
    }

    func clear() {
        KeychainHelper.delete(key: key)
    }
}

enum KeychainHelper {
    private static let service = Bundle.main.bundleIdentifier ?? "com.pc.fash"

    static func save(_ data: Data, key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false,
            kSecValueData as String: data,
        ]
        SecItemDelete(baseQuery(key: key) as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> Data? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    static func delete(key: String) {
        SecItemDelete(baseQuery(key: key) as CFDictionary)
    }

    private static func baseQuery(key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
