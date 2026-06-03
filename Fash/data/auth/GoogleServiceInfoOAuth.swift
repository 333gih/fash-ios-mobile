import Foundation

/// Reads OAuth client ids from the bundled `GoogleService-Info.plist` (Firebase download).
enum GoogleServiceInfoOAuth {
    private static let plistName = "GoogleService-Info"

    static var clientId: String {
        string(for: "CLIENT_ID")
    }

    static var reversedClientId: String {
        let explicit = string(for: "REVERSED_CLIENT_ID")
        if !explicit.isEmpty { return explicit }
        return GoogleSignInClients.reversedUrlScheme(from: clientId)
    }

    private static func string(for key: String) -> String {
        guard let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist[key] as? String
        else { return "" }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
