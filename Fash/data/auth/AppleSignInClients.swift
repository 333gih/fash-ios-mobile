import AuthenticationServices
import Foundation
import UIKit

/// Sign in with Apple — identity token sent to auth-service `provider=apple`.
enum AppleSignInClients {
    enum SignInError: Error {
        case cancelled
        case missingIdentityToken
        case noPresentationAnchor
        case notAvailable
    }

    static func isAvailable() -> Bool {
        // ASAuthorizationAppleIDProvider is available on iOS 13+; we target newer OS.
        true
    }

    @MainActor
    static func signIn() async throws -> String {
        guard isAvailable() else { throw SignInError.notAvailable }
        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = Coordinator(continuation: continuation)
            Coordinator.retain(coordinator)
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = coordinator
            controller.presentationContextProvider = coordinator
            coordinator.controller = controller
            controller.performRequests()
        }
    }

    static func userMessage(for error: Error) -> String {
        if let signInError = error as? SignInError {
            switch signInError {
            case .cancelled:
                return ""
            case .notAvailable:
                return L10n.loginAppleUnavailable
            case .missingIdentityToken, .noPresentationAnchor:
                return L10n.loginAppleError
            }
        }
        let ns = error as NSError
        if ns.domain == ASAuthorizationError.errorDomain {
            switch ASAuthorizationError.Code(rawValue: ns.code) {
            case .canceled, .unknown:
                return ""
            case .notHandled:
                return L10n.loginAppleNotHandled
            case .failed:
                return L10n.loginAppleError
            case .invalidResponse:
                return L10n.loginAppleInvalidResponse
            case .notInteractive:
                return L10n.loginAppleNotInteractive
            @unknown default:
                return L10n.loginAppleError
            }
        }
        #if DEBUG
        let detail = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        if !detail.isEmpty {
            return "\(L10n.loginAppleError) (\(detail))"
        }
        #endif
        return L10n.loginAppleError
    }
}

@MainActor
private final class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private static var retained: Coordinator?

    static func retain(_ coordinator: Coordinator) {
        retained = coordinator
    }

    static func release() {
        retained = nil
    }

    private let continuation: CheckedContinuation<String, Error>
    private var finished = false
    weak var controller: ASAuthorizationController?

    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = RootViewControllerFinder.keyWindow() {
            return window
        }
        finish(.failure(AppleSignInClients.SignInError.noPresentationAnchor))
        return UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8),
              !token.isEmpty
        else {
            finish(.failure(AppleSignInClients.SignInError.missingIdentityToken))
            return
        }
        finish(.success(token))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let ns = error as NSError
        if ns.domain == ASAuthorizationError.errorDomain,
           ns.code == ASAuthorizationError.canceled.rawValue {
            finish(.failure(AppleSignInClients.SignInError.cancelled))
            return
        }
        finish(.failure(error))
    }

    private func finish(_ result: Result<String, Error>) {
        guard !finished else { return }
        finished = true
        Self.release()
        switch result {
        case .success(let token):
            continuation.resume(returning: token)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
