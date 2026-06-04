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
        resolved(AppEnvironment.googleWebClientId)
    }

    /// Build-time env (`GOOGLE_IOS_CLIENT_ID`) or `CLIENT_ID` from bundled GoogleService-Info.plist.
    static var resolvedIosClientId: String {
        let fromEnv = resolved(AppEnvironment.googleIosClientId)
        if !fromEnv.isEmpty { return fromEnv }
        return resolved(GoogleServiceInfoOAuth.clientId)
    }

    static func reversedUrlScheme(from iosClientId: String) -> String {
        let trimmed = iosClientId.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = ".apps.googleusercontent.com"
        guard !trimmed.isEmpty, trimmed.hasSuffix(suffix) else { return "" }
        let prefix = String(trimmed.dropLast(suffix.count))
        return "com.googleusercontent.apps.\(prefix)"
    }

    static func isConfigured() -> Bool {
        configurationDiagnostics().isReady
    }

    /// Mirrors Android `isGoogleConfigured()` (web id) plus iOS-native client id required by GoogleSignIn-iOS.
    struct ConfigurationDiagnostics {
        let webClientId: String
        let iosClientId: String
        let plistClientId: String
        let envIosClientId: String

        var isReady: Bool {
            guard !webClientId.isEmpty, !iosClientId.isEmpty else { return false }
            if webClientId.uppercased().hasPrefix("YOUR_") || iosClientId.uppercased().hasPrefix("YOUR_") {
                return false
            }
            return true
        }

        var userMessage: String {
            if webClientId.isEmpty {
                return L10n.loginGoogleNotConfigured
            }
            if iosClientId.isEmpty {
                return L10n.loginGoogleIosSetup
            }
            return L10n.loginGoogleNotConfigured
        }
    }

    static func configurationDiagnostics() -> ConfigurationDiagnostics {
        let web = webClientId
        let envIos = resolved(AppEnvironment.googleIosClientId)
        let plistIos = resolved(GoogleServiceInfoOAuth.clientId)
        let ios = resolvedIosClientId
        return ConfigurationDiagnostics(
            webClientId: web,
            iosClientId: ios,
            plistClientId: plistIos,
            envIosClientId: envIos
        )
    }

    static func notConfiguredUserMessage() -> String {
        configurationDiagnostics().userMessage
    }

    private static func resolved(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func configureIfNeeded() {
        guard isConfigured() else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: resolvedIosClientId,
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
    static func keyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first(where: { $0.activationState == .foregroundInactive })
            ?? scenes.first
        return scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first
    }

    @MainActor
    static func topmost() -> UIViewController? {
        guard let root = keyWindow()?.rootViewController else { return nil }
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
