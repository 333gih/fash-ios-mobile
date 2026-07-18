import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

/// Push transport coordinator — parity with personal-os `POSPushCoordinator`.
///
/// Default path: Firebase Cloud Messaging when `USE_FIREBASE_MESSAGING` is true and
/// `GoogleService-Info.plist` is bundled. Fallback: hex-encoded APNs device token registered
/// directly with fash-auth (`api/v1/auth/fcm/register`).
@MainActor
final class PushNotificationCoordinator: NSObject {
    static let shared = PushNotificationCoordinator()

    static let apnsDeviceTokenKey = "fash.apns.device_token"

    private var hasRequestedAuthorization = false

    /// True when a Firebase config plist is bundled (CI decodes the secret before archive).
    static var isFirebaseConfigured: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    /// Effective transport: Firebase FCM only when the flag is on AND the plist is present.
    static var usesFirebaseMessaging: Bool {
        BuildConfig.useFirebaseMessaging && isFirebaseConfigured
    }

    /// Call once from `didFinishLaunchingWithOptions`.
    static func configureMessagingIfNeeded() {
        UNUserNotificationCenter.current().delegate = PushNotificationCoordinator.shared
        guard usesFirebaseMessaging else {
            if BuildConfig.useFirebaseMessaging && !isFirebaseConfigured {
                PushDiagnostics.warning("GoogleService-Info.plist missing — FCM disabled, using pure APNs registration")
            } else {
                PushDiagnostics.info("USE_FIREBASE_MESSAGING=false — using pure APNs registration")
            }
            return
        }
        validateFirebasePlistBundleId()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            if let projectId = firebasePlistValue("PROJECT_ID") {
                PushDiagnostics.info("Firebase configured (project=\(projectId))")
            } else {
                PushDiagnostics.info("Firebase configured")
            }
        }
        Messaging.messaging().delegate = PushNotificationCoordinator.shared
        PushDiagnostics.info("Firebase FCM configured")
    }

    /// Maps APNs environment to FCM token type.
    /// - Dev bundle (`*.dev`) + Dev entitlements → sandbox (all build configs).
    /// - Prod bundle + Xcode debug install → sandbox (development signing).
    /// - Prod bundle + TestFlight/App Store (Release) → production.
    static func apnsTokenTypeForCurrentBuild() -> MessagingAPNSTokenType {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        if bundleId.hasSuffix(".dev") {
            return .sandbox
        }
        #if DEBUG
        return .sandbox
        #else
        return .prod
        #endif
    }

    static func applyAPNSToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: apnsDeviceTokenKey)

        guard usesFirebaseMessaging else {
            PushDiagnostics.info("APNs token stored (pure APNs path, hex length=\(hex.count))")
            Task { @MainActor in
                await AppDependencies.shared.fcmTokenRegistrar.registerPendingToken()
            }
            return
        }

        let type = apnsTokenTypeForCurrentBuild()
        Messaging.messaging().setAPNSToken(deviceToken, type: type)
        let bundleId = Bundle.main.bundleIdentifier ?? "?"
        let plistBundle = firebasePlistValue("BUNDLE_ID") ?? "?"
        PushDiagnostics.info(
            "APNs token set (type=\(type == .prod ? "production" : "sandbox"), app=\(bundleId), plist=\(plistBundle))"
        )
        Task { @MainActor in
            await PushNotificationCoordinator.shared.registerCurrentTokenIfSession()
        }
    }

    private static func firebasePlistValue(_ key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String
        else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func validateFirebasePlistBundleId() {
        guard let plistBundle = firebasePlistValue("BUNDLE_ID"),
              let appBundle = Bundle.main.bundleIdentifier
        else { return }
        if plistBundle != appBundle {
            PushDiagnostics.error(
                "GoogleService-Info BUNDLE_ID (\(plistBundle)) != app bundle (\(appBundle)) — FCM/APNs delivery will fail (apns_auth). Copy GoogleService-Info-Dev.plist for Fash-Dev or prod plist for Fash-Prod."
            )
        }
    }

    private static var isAPNsLinked: Bool {
        Messaging.messaging().apnsToken != nil
    }

    /// If the user already granted permission, register with APNs on cold start (before login UI).
    func syncRemoteNotificationRegistrationOnLaunch() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await UIApplication.shared.registerForRemoteNotifications()
            PushDiagnostics.info("registerForRemoteNotifications (authorization already granted)")
        default:
            break
        }
    }

    /// Call after login / session bootstrap (Android `FcmTokenRegistrar.registerCurrentTokenIfSession`).
    func registerCurrentTokenIfSession() async {
        if usesFirebaseMessaging {
            await registerCurrentFCMTokenIfSession()
        } else {
            await AppDependencies.shared.fcmTokenRegistrar.registerPendingToken()
        }
    }

    private func registerCurrentFCMTokenIfSession() async {
        for attempt in 0..<12 {
            if !Self.isAPNsLinked {
                if attempt == 0 {
                    PushDiagnostics.warning("FCM register deferred — waiting for APNs device token")
                }
                try? await Task.sleep(for: .milliseconds(500))
                continue
            }
            if let token = await Self.fetchFCMToken(), !token.isEmpty {
                let apnsType = Self.apnsTokenTypeForCurrentBuild() == .prod ? "production" : "sandbox"
                PushDiagnostics.logTokenMetadata(token, context: "FCM token ready (apns_type=\(apnsType))")
                await AppDependencies.shared.fcmTokenRegistrar.registerDeviceToken(token)
                return
            }
            if attempt < 11 {
                try? await Task.sleep(for: .milliseconds(500 * min(attempt + 1, 4)))
            }
        }
        if !Self.isAPNsLinked {
            PushDiagnostics.error("APNs token never received — check Push capability, provisioning profile, and notification permission")
        } else {
            PushDiagnostics.error("FCM token unavailable after retries — check APNs token type, GoogleService-Info BUNDLE_ID, and Firebase APNs key")
        }
    }

    /// Clears local FCM registration on logout so stale tokens are not reused server-side.
    static func clearFCMRegistrationOnLogout() async {
        FcmTokenRegistrar.clearPendingToken()
        UserDefaults.standard.removeObject(forKey: apnsDeviceTokenKey)
        guard usesFirebaseMessaging else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Messaging.messaging().deleteToken { error in
                if let error {
                    PushDiagnostics.warning("FCM deleteToken on logout: \(error.localizedDescription)")
                } else {
                    PushDiagnostics.info("FCM token deleted on logout")
                }
                continuation.resume()
            }
        }
    }

    /// Requests notification permission and registers with APNs (required before FCM token on real device).
    func requestAuthorizationAndRegisterForRemoteNotifications() async {
        guard !hasRequestedAuthorization else {
            await UIApplication.shared.registerForRemoteNotifications()
            return
        }
        hasRequestedAuthorization = true
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            PushDiagnostics.info("notification authorization granted=\(granted)")
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            PushDiagnostics.error("authorization request failed: \(error.localizedDescription)")
        }
    }

    static func fetchFCMToken() async -> String? {
        await withCheckedContinuation { continuation in
            Messaging.messaging().token { token, error in
                if let error {
                    PushDiagnostics.error("FCM token fetch failed: \(error.localizedDescription)")
                }
                continuation.resume(returning: token)
            }
        }
    }

    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        FashFirebaseMessagingService.handleNotificationTap(userInfo: userInfo)
    }

    func handleForegroundNotification(userInfo: [AnyHashable: Any]) {
        FashFirebaseMessagingService.handleForegroundNotification(userInfo: userInfo)
    }

    func appDidReceiveRemoteMessage(_ userInfo: [AnyHashable: Any]) {
        guard Self.usesFirebaseMessaging else { return }
        Messaging.messaging().appDidReceiveMessage(userInfo)
    }
}

extension PushNotificationCoordinator: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        PushDiagnostics.logTokenMetadata(fcmToken, context: "MessagingDelegate token refresh")
        Task { @MainActor in
            await AppDependencies.shared.fcmTokenRegistrar.registerDeviceToken(fcmToken)
        }
    }
}

extension PushNotificationCoordinator: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        await MainActor.run {
            PushNotificationCoordinator.shared.handleForegroundNotification(userInfo: userInfo)
        }
        return [.banner, .list, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        await MainActor.run {
            PushNotificationCoordinator.shared.handleNotificationTap(userInfo: userInfo)
        }
    }
}
