import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var otp = ""
    var isOtpLoading = false
    var errorMessage: String?

    private let auth = AuthRepository()

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
        case .failure:
            errorMessage = L10n.dialogTitleError
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
            return true
        case .failure:
            errorMessage = L10n.loginOtpFailed
            return false
        }
    }
}
