import Foundation

// MARK: - Auth wire models (Android: data/auth/)
// Session persistence lives in AuthSessionStore.swift (`AuthSession`).

struct OtpRequestResponse: Equatable {
    let success: Bool
    let message: String?
}

struct SocialLoginRequest: Equatable {
    let provider: String
    let idToken: String
}

struct TokenRefreshResponse: Equatable {
    let accessToken: String
    let refreshToken: String?
}
