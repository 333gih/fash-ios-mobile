import Foundation
import Observation

@Observable
@MainActor
final class ChangePasswordViewModel {
    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""
    var isSubmitting = false
    var eventMessage: String?

    func onCurrentPasswordChange(_ value: String) {
        currentPassword = String(value.prefix(72))
    }

    func onNewPasswordChange(_ value: String) {
        newPassword = String(value.prefix(72))
    }

    func onConfirmPasswordChange(_ value: String) {
        confirmPassword = String(value.prefix(72))
    }

    func canSubmit() -> Bool {
        !currentPassword.trimmingCharacters(in: .whitespaces).isEmpty
            && (8...72).contains(newPassword.count)
            && newPassword == confirmPassword
    }

    func submit(deps: AppDependencies) async {
        guard canSubmit(), !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        switch await deps.userRepository.putUserPassword(newPassword: newPassword, currentPassword: currentPassword) {
        case .success:
            _ = await AuthTokenRefreshCoordinator.refreshIfStillCurrent(
                sessionStore: deps.authSessionStore,
                authRepository: deps.authRepository,
                accessTokenWhenUnauthorized: deps.authSessionStore.read()?.accessToken ?? ""
            )
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            eventMessage = L10n.passwordChangeSuccess
        case .failure(let err):
            eventMessage = mapPasswordError(err)
        }
    }

    private func mapPasswordError(_ error: Error) -> String {
        let raw = error.localizedDescription
        if raw.contains("PASSWORD_LENGTH") { return L10n.passwordErrorLength }
        if raw.contains("INVALID_CURRENT_PASSWORD") { return L10n.passwordErrorInvalidCurrent }
        if raw.contains("CURRENT_PASSWORD_REQUIRED") { return L10n.passwordErrorCurrentRequired }
        return raw.isEmpty ? L10n.passwordChangeErrorGeneric : raw
    }
}
