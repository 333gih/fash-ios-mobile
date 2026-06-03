import AuthenticationServices
import Foundation
import UIKit

/// Sign in with Apple — identity token sent to auth-service `provider=apple`.
enum AppleSignInClients {
    enum SignInError: Error {
        case cancelled
        case missingIdentityToken
        case noPresentationAnchor
    }

    @MainActor
    static func signIn() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let coordinator = Coordinator(continuation: continuation)
            Coordinator.active = coordinator
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
}

@MainActor
private final class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static var active: Coordinator?
    private let continuation: CheckedContinuation<String, Error>
    private var finished = false
    weak var controller: ASAuthorizationController?

    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
            ?? scenes.first
        if let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first {
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
        Self.active = nil
        switch result {
        case .success(let token):
            continuation.resume(returning: token)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
