import Foundation
import Observation

private let otpLength = 6
private let defaultResendCooldownSec = 60

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var otp = ""
    var usePasswordLogin = false
    var isOtpLoading = false
    var isVerifyLoading = false
    var isPasswordLoading = false
    var isSocialLoading = false
    var errorMessage: String?
    var resendCooldownSec = 0

    private let auth = AuthRepository()
    private var resendCooldownTask: Task<Void, Never>?

    static func isGoogleConfigured() -> Bool {
        GoogleSignInClients.isConfigured()
    }

    func togglePasswordLogin() {
        usePasswordLogin.toggle()
    }

    func requestOtp() async -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard LoginEmailValidation.isValid(trimmed) else {
            errorMessage = L10n.loginEmailInvalid
            return false
        }
        isOtpLoading = true
        defer { isOtpLoading = false }
        let result = await auth.requestOtp(email: trimmed)
        switch result {
        case .success:
            startResendCooldown(defaultResendCooldownSec)
            return true
        case .failure(let error):
            handleOtpRequestFailure(error)
            return false
        }
    }

    func verifyOtp(sessionStore: AuthSessionStore) async -> Bool {
        guard otp.count == otpLength else {
            errorMessage = L10n.otpInvalidLength
            return false
        }
        isVerifyLoading = true
        defer { isVerifyLoading = false }
        let result = await auth.verifyOtp(email: email, otp: otp)
        switch result {
        case .success(let session):
            sessionStore.save(session)
            AppDependencies.shared.invalidateSessionValidationForLogin()
            AppDependencies.shared.authManager.onSessionSaved()
            return true
        case .failure(let error):
            errorMessage = authFailureMessage(error, otpContext: true, fallback: L10n.otpVerifyFailed)
            return false
        }
    }

    func loginWithPassword(sessionStore: AuthSessionStore) async -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard LoginEmailValidation.isValid(trimmed) else {
            errorMessage = L10n.loginEmailInvalid
            return false
        }
        guard !password.isEmpty else {
            errorMessage = L10n.loginPasswordInvalid
            return false
        }
        isPasswordLoading = true
        defer { isPasswordLoading = false }
        let result = await auth.login(email: trimmed, password: password)
        switch result {
        case .success(let session):
            sessionStore.save(session)
            AppDependencies.shared.invalidateSessionValidationForLogin()
            AppDependencies.shared.authManager.onSessionSaved()
            return true
        case .failure(let error):
            errorMessage = authFailureMessage(error, otpContext: false, fallback: L10n.loginPasswordFailed)
            return false
        }
    }

    func performGoogleSignIn(sessionStore: AuthSessionStore) async -> Bool {
        guard Self.isGoogleConfigured() else {
            errorMessage = L10n.loginGoogleNotConfigured
            return false
        }
        guard let presenter = RootViewControllerFinder.topmost() else {
            errorMessage = L10n.loginGoogleError
            return false
        }
        isSocialLoading = true
        defer { isSocialLoading = false }
        do {
            let idToken = try await GoogleSignInClients.signIn(presenting: presenter)
            return await completeSocialLogin(idToken: idToken, sessionStore: sessionStore)
        } catch GoogleSignInClients.SignInError.cancelled {
            return false
        } catch {
            if let message = GoogleSignInClients.userMessage(for: error) {
                errorMessage = message
            }
            return false
        }
    }

    func warnGoogleNotConfigured() {
        errorMessage = L10n.loginGoogleNotConfigured
    }

    private func completeSocialLogin(idToken: String, sessionStore: AuthSessionStore) async -> Bool {
        let result = await auth.socialLogin(provider: "google", providerToken: idToken)
        switch result {
        case .success(let session):
            sessionStore.save(session)
            AppDependencies.shared.invalidateSessionValidationForLogin()
            AppDependencies.shared.authManager.onSessionSaved()
            return true
        case .failure(let error):
            errorMessage = authFailureMessage(error, otpContext: false, fallback: L10n.loginGoogleError)
            return false
        }
    }

    private func handleOtpRequestFailure(_ error: Error) {
        if let http = error as? CoreServiceHttpException, http.isRateLimited {
            if let retry = http.retryAfterSeconds, retry > 0 {
                startResendCooldown(retry)
            }
        }
        errorMessage = authFailureMessage(error, otpContext: true, fallback: L10n.loginOtpFailed)
    }

    private func authFailureMessage(_ error: Error, otpContext: Bool, fallback: String) -> String {
        if let http = error as? CoreServiceHttpException, http.isRateLimited {
            return CoreServiceErrors.localizedMessage(http.serviceError, otpContext: otpContext)
        }
        if let localized = (error as? LocalizedError)?.errorDescription, !localized.isEmpty {
            return localized
        }
        return fallback
    }

    private func startResendCooldown(_ seconds: Int) {
        resendCooldownTask?.cancel()
        resendCooldownSec = max(1, seconds)
        resendCooldownTask = Task {
            while resendCooldownSec > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                resendCooldownSec = max(0, resendCooldownSec - 1)
            }
        }
    }
}
