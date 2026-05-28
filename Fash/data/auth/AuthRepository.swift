import Foundation

/// Auth-service HTTP — Android [AuthRepository].
final class AuthRepository {
    private let applicationId: String

    init(applicationId: String = AppEnvironment.authApplicationId) {
        self.applicationId = applicationId.trimmingCharacters(in: .whitespaces)
    }

    func requestOtp(email: String) async -> Result<Bool, Error> {
        do {
            let data = try await HttpJson.post(url: AppEnvironment.authServicePath(AppEnvironment.authOtpRequestPath), body: [
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

    func login(email: String, password: String) async -> Result<AuthSession, Error> {
        do {
            let data = try await HttpJson.post(url: AppEnvironment.authServicePath(AppEnvironment.authLoginPath), body: [
                "email": email.trimmingCharacters(in: .whitespaces),
                "password": password,
                "application_id": applicationId,
            ])
            return .success(try parseLoginResponse(data))
        } catch {
            return .failure(error)
        }
    }

    func verifyOtp(email: String, otp: String) async -> Result<AuthSession, Error> {
        do {
            let data = try await HttpJson.post(url: AppEnvironment.authServicePath(AppEnvironment.authOtpVerifyPath), body: [
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
            let data = try await HttpJson.post(url: AppEnvironment.authServicePath(AppEnvironment.authRefreshPath), body: [
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
            let data = try await HttpJson.post(url: AppEnvironment.authServicePath(AppEnvironment.authSocialLoginPath), body: [
                "provider": provider.lowercased(),
                "provider_token": providerToken.trimmingCharacters(in: .whitespaces),
                "application_id": applicationId,
            ])
            return .success(try parseLoginResponse(data))
        } catch {
            return .failure(error)
        }
    }

    func logout(accessToken: String) async -> Result<Void, Error> {
        do {
            _ = try await HttpJson.post(
                url: AppEnvironment.authServicePath(AppEnvironment.authLogoutPath),
                body: [:],
                bearer: accessToken
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func logoutAll(accessToken: String) async -> Result<Void, Error> {
        do {
            _ = try await HttpJson.post(
                url: AppEnvironment.authServicePath(AppEnvironment.authLogoutAllPath),
                body: [:],
                bearer: accessToken
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func registerFcm(
        accessToken: String,
        token: String,
        platform: String = "ios",
        clientLocale: String? = nil
    ) async -> Result<Void, Error> {
        do {
            var body: [String: String] = [
                "fcm_token": token.trimmingCharacters(in: .whitespaces),
                "device_platform": platform,
            ]
            if let loc = clientLocale?.trimmingCharacters(in: .whitespaces), !loc.isEmpty {
                body["client_locale"] = loc
            }
            _ = try await HttpJson.post(
                url: AppEnvironment.authServicePath(AppEnvironment.authFcmRegisterPath),
                body: body,
                bearer: accessToken
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func parseLoginResponse(_ data: Data) throws -> AuthSession {
        let root = try HttpJson.dictionary(data)
        let json: [String: Any]
        if let nested = root["data"] as? [String: Any] {
            json = nested
        } else {
            json = root
        }
        let access = json["access_token"] as? String ?? ""
        let refresh = json["refresh_token"] as? String ?? ""
        let type = (json["token_type"] as? String)?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? (json["token_type"] as? String ?? "Bearer")
            : "Bearer"
        let userId = json["user_id"] as? String
        let expiresIn: Int64 = {
            if let n = json["expires_in"] as? NSNumber { return n.int64Value }
            if let s = json["expires_in"] as? String, let v = Int64(s) { return v }
            return 0
        }()
        let isNewUser = json["is_new_user"] as? Bool ?? false
        let unreadCount = (json["unread_count"] as? NSNumber)?.int64Value ?? 0
        guard !access.isEmpty else { throw URLError(.userAuthenticationRequired) }
        return AuthSession(
            accessToken: access,
            refreshToken: refresh,
            tokenType: type,
            userId: userId,
            expiresInSeconds: max(0, expiresIn),
            isNewUser: isNewUser,
            unreadCount: max(0, unreadCount)
        )
    }
}
