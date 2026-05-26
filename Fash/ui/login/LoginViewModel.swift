import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var otp = ""
    var isOtpLoading = false
    var errorMessage: String?
    var resendCooldownSec = 0

    private let auth = AuthRepository()
    private var resendCooldownTask: Task<Void, Never>?

    func requestOtp() async -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@") else {
            errorMessage = L10n.loginEmailInvalid
            return false
        }
        isOtpLoading = true
        defer { isOtpLoading = false }
        let result = await auth.requestOtp(email: trimmed)
        switch result {
        case .success:
            return true
        case .failure(let error):
            handleOtpRequestFailure(error)
            return false
        }
    }

    func verifyOtp(sessionStore: AuthSessionStore) async -> Bool {
        isOtpLoading = true
        defer { isOtpLoading = false }
        let result = await auth.verifyOtp(email: email, otp: otp)
        switch result {
        case .success(let session):
            sessionStore.save(session)
            AppDependencies.shared.authManager.onSessionSaved()
            return true
        case .failure(let error):
            errorMessage = authFailureMessage(error, otpContext: true, fallback: L10n.otpVerifyFailed)
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
