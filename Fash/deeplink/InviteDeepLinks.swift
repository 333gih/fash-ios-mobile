import Foundation

/// Invite deep links — Android `InviteDeepLinks`.
enum InviteDeepLinks {
    static func inviteDeepLinkURL(referrerUsername: String?, referralToken: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "fash"
        components.host = "invite"
        var items: [URLQueryItem] = []
        let user = referrerUsername?.trimmingCharacters(in: .whitespaces) ?? ""
        if !user.isEmpty { items.append(URLQueryItem(name: "ref", value: user)) }
        let token = referralToken?.trimmingCharacters(in: .whitespaces) ?? ""
        if !token.isEmpty { items.append(URLQueryItem(name: "r", value: token)) }
        components.queryItems = items.isEmpty ? nil : items
        return components.url
    }

    static func publicInviteHttpsURL(referrerUsername: String?, referralToken: String? = nil) -> String {
        let raw = AppEnvironment.listingShareBaseURL.trimmingCharacters(in: .whitespaces)
        let withScheme = raw.contains("://") ? raw : "https://\(raw)"
        guard var origin = URL(string: withScheme) else {
            return fallbackInviteURL(referrerUsername: referrerUsername, referralToken: referralToken)
        }
        if origin.host == nil { origin = URL(string: "https://fash.app/p/l")! }
        var host = origin.host ?? "fash.app"
        let scheme = origin.scheme ?? "https"
        var invite = URLComponents()
        invite.scheme = scheme
        invite.host = host
        invite.path = "/invite"
        var items: [URLQueryItem] = []
        let user = referrerUsername?.trimmingCharacters(in: .whitespaces) ?? ""
        if !user.isEmpty { items.append(URLQueryItem(name: "ref", value: user)) }
        let token = referralToken?.trimmingCharacters(in: .whitespaces) ?? ""
        if !token.isEmpty { items.append(URLQueryItem(name: "r", value: token)) }
        invite.queryItems = items.isEmpty ? nil : items
        return invite.url?.absoluteString ?? fallbackInviteURL(referrerUsername: referrerUsername, referralToken: referralToken)
    }

    private static func fallbackInviteURL(referrerUsername: String?, referralToken: String?) -> String {
        var components = URLComponents(string: "https://fash.app/invite")!
        var items: [URLQueryItem] = []
        if let user = referrerUsername?.trimmingCharacters(in: .whitespaces), !user.isEmpty {
            items.append(URLQueryItem(name: "ref", value: user))
        }
        if let token = referralToken?.trimmingCharacters(in: .whitespaces), !token.isEmpty {
            items.append(URLQueryItem(name: "r", value: token))
        }
        components.queryItems = items.isEmpty ? nil : items
        return components.url?.absoluteString ?? "https://fash.app/invite"
    }

    static func parseReferrer(from url: URL) -> String? {
        guard isInviteURL(url) else { return nil }
        let ref = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "ref" })?
            .value?
            .trimmingCharacters(in: .whitespaces)
        return ref?.isEmpty == false ? ref : nil
    }

    static func parseReferralToken(from url: URL) -> String? {
        guard isInviteURL(url) else { return nil }
        let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "r" })?
            .value?
            .trimmingCharacters(in: .whitespaces) ?? ""
        guard token.count >= 16, token.count <= 8192 else { return nil }
        return token
    }

    private static func isInviteURL(_ url: URL) -> Bool {
        if url.scheme?.lowercased() == "fash", url.host?.lowercased() == "invite" { return true }
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else { return false }
        guard let host = url.host?.lowercased(), let expected = listingShareHost() else { return false }
        guard host == expected else { return false }
        return url.pathComponents.contains(where: { $0.caseInsensitiveCompare("invite") == .orderedSame })
    }

    private static func listingShareHost() -> String? {
        let raw = AppEnvironment.listingShareBaseURL.trimmingCharacters(in: .whitespaces)
        let withScheme = raw.contains("://") ? raw : "https://\(raw)"
        return URL(string: withScheme)?.host?.lowercased()
    }
}
