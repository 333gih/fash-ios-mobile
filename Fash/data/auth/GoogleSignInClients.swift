import Foundation
import GoogleSignIn
import UIKit

/// Port of Android `GoogleSignInClients` (data.auth).
enum GoogleSignInClients {
    enum SignInError: Error {
        case notConfigured
        case noPresenter
        case missingIdToken
        case cancelled
    }

    private static var webClientId: String {
        AppEnvironment.googleWebClientId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static var iosClientId: String {
        AppEnvironment.googleIosClientId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isConfigured() -> Bool {
        let web = webClientId
        let ios = iosClientId
        guard !web.isEmpty, !ios.isEmpty else { return false }
        if web.uppercased().hasPrefix("YOUR_") || ios.uppercased().hasPrefix("YOUR_") { return false }
        return true
    }

    static func configureIfNeeded() {
        guard isConfigured() else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: iosClientId,
            serverClientID: webClientId
        )
    }

    @MainActor
    static func signIn(presenting viewController: UIViewController) async throws -> String {
        guard isConfigured() else { throw SignInError.notConfigured }
        configureIfNeeded()
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let token = result.user.idToken?.tokenString, !token.isEmpty else {
                throw SignInError.missingIdToken
            }
            return token
        } catch let error as GIDSignInError where error.code == .canceled {
            throw SignInError.cancelled
        }
    }

    static func handle(url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    static func signOut() {
        guard isConfigured() else { return }
        GIDSignIn.sharedInstance.signOut()
    }

    static func userMessage(for error: Error) -> String? {
        if let signInError = error as? SignInError {
            switch signInError {
            case .cancelled:
                return nil
            case .notConfigured:
                return L10n.loginGoogleNotConfigured
            case .noPresenter, .missingIdToken:
                return L10n.loginGoogleError
            }
        }
        if let signInError = error as? GIDSignInError, signInError.code == .canceled {
            return nil
        }
        if let nsError = error as NSError?, nsError.domain == kGIDSignInErrorDomain {
            if nsError.code == GIDSignInError.canceled.rawValue {
                return nil
            }
            #if DEBUG
            return L10n.loginGoogleErrorCode(nsError.code, nsError.localizedDescription)
            #else
            return L10n.loginGoogleError
            #endif
        }
        let message = (error as? LocalizedError)?.errorDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        return message?.isEmpty == false ? message : L10n.loginGoogleError
    }
}

enum RootViewControllerFinder {
    @MainActor
    static func topmost() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }),
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController ?? scene.windows.first?.rootViewController
        else { return nil }
        return topMost(from: root)
    }

    @MainActor
    private static func topMost(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topMost(from: presented)
        }
        if let navigation = viewController as? UINavigationController,
           let visible = navigation.visibleViewController {
            return topMost(from: visible)
        }
        if let tab = viewController as? UITabBarController,
           let selected = tab.selectedViewController {
            return topMost(from: selected)
        }
        return viewController
    }
}
