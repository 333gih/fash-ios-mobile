import Foundation

/// Auth-service HTTP (Android [AuthRepository]).
final class AuthRepository {
    private let applicationId: String

    init(applicationId: String = BuildConfig.authApplicationId) {
        self.applicationId = applicationId.trimmingCharacters(in: .whitespaces)
    }

    func requestOtp(email: String) async -> Result<Bool, Error> {
        do {
            let url = AppEnvironment.authServicePath(BuildConfigPaths.authOtpRequest)
            let data = try await HttpJson.post(url: url, body: [
                "email": email.trimmingCharacters(in: .whitespaces),
                "application_id": applicationId,
            ])
            if data.isEmpty { return .success(false) }
            let json = try HttpJson.dictionary(data)
            return .success(json["is_new_user"] as? Bool ?? false)
        } catch {
            return .failure(error)
        }
    }

    func verifyOtp(email: String, otp: String) async -> Result<AuthSession, Error> {
        do {
            let url = AppEnvironment.authServicePath(BuildConfigPaths.authOtpVerify)
            let data = try await HttpJson.post(url: url, body: [
                "email": email.trimmingCharacters(in: .whitespaces),
                "otp": otp.trimmingCharacters(in: .whitespaces),
                "application_id": applicationId,
            ])
            return .success(try parseLoginResponse(data))
        } catch {
            return .failure(error)
        }
    }

    func refresh(refreshToken: String) async -> Result<AuthSession, Error> {
        do {
            let url = AppEnvironment.authServicePath(BuildConfigPaths.authRefresh)
            let data = try await HttpJson.post(url: url, body: [
                "application_id": applicationId,
                "refresh_token": refreshToken.trimmingCharacters(in: .whitespaces),
                "user_agent": "Fash-iOS/1.0.3",
                "ip_address": ClientIpAddress.localIpv4OrEmpty(),
            ])
            return .success(try parseLoginResponse(data))
        } catch {
            return .failure(error)
        }
    }

    func socialLogin(provider: String, providerToken: String) async -> Result<AuthSession, Error> {
        do {
            let url = AppEnvironment.authServicePath(BuildConfigPaths.authSocialLogin)
            let data = try await HttpJson.post(url: url, body: [
                "provider": provider.lowercased(),
                "provider_token": providerToken.trimmingCharacters(in: .whitespaces),
                "application_id": applicationId,
            ])
            return .success(try parseLoginResponse(data))
        } catch {
            return .failure(error)
        }
    }

    private func parseLoginResponse(_ data: Data) throws -> AuthSession {
        let json = try HttpJson.dictionary(data)
        let access = json["access_token"] as? String ?? ""
        let refresh = json["refresh_token"] as? String ?? ""
        let type = json["token_type"] as? String ?? "Bearer"
        let userId = json["user_id"] as? String
        guard !access.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        return AuthSession(accessToken: access, refreshToken: refresh, tokenType: type, userId: userId)
    }
}

enum BuildConfigPaths {
    static let authOtpRequest = "api/v1/auth/otp/request"
    static let authOtpVerify = "api/v1/auth/otp/verify"
    static let authRefresh = "api/v1/auth/refresh"
    static let authSocialLogin = "api/v1/auth/social-login"
    static let authLogin = "api/v1/auth/login"
}
