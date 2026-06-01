import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

/// Requests APNs permission, bridges FCM token refresh, and routes notification taps — Android `FcmTokenRegistrar` + tray handling.
@MainActor
final class PushNotificationCoordinator: NSObject {
    static let shared = PushNotificationCoordinator()

    private var hasRequestedAuthorization = false

    static var isFirebaseConfigured: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    static func configureFirebaseIfNeeded() {
        guard isFirebaseConfigured else {
            PushDiagnostics.warning("GoogleService-Info.plist missing — FCM disabled")
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            PushDiagnostics.info("Firebase configured")
        }
    }

    /// Sandbox only for the dev bundle id; TestFlight/App Store prod bundle always uses production APNs.
    static func apnsTokenTypeForCurrentBuild() -> MessagingAPNSTokenType {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        if bundleId.hasSuffix(".dev") {
            return .sandbox
        }
        return .prod
    }

    static func applyAPNSToken(_ deviceToken: Data) {
        guard isFirebaseConfigured else { return }
        let type = apnsTokenTypeForCurrentBuild()
        Messaging.messaging().setAPNSToken(deviceToken, type: type)
        PushDiagnostics.info("APNs token set (type=\(type == .prod ? "production" : "sandbox"))")
    }

    /// If the user already granted permission, register with APNs on cold start (before login UI).
    func syncRemoteNotificationRegistrationOnLaunch() async {
        guard Self.isFirebaseConfigured else { return }
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
        guard Self.isFirebaseConfigured else { return }
        guard AppDependencies.shared.authSessionStore.read() != nil else { return }
        for attempt in 0..<6 {
            if let token = await Self.fetchFCMToken(), !token.isEmpty {
                PushDiagnostics.info("FCM token ready (prefix=\(Self.tokenLogPrefix(token)))")
                await AppDependencies.shared.fcmTokenRegistrar.registerDeviceToken(token)
                return
            }
            if attempt < 5 {
                try? await Task.sleep(for: .milliseconds(500 * (attempt + 1)))
            }
        }
        PushDiagnostics.error("FCM token unavailable after retries — check APNs token type, permission, and Firebase APNs key")
    }

    private static func tokenLogPrefix(_ token: String) -> String {
        let t = token.trimmingCharacters(in: .whitespaces)
        guard t.count > 12 else { return t }
        return String(t.prefix(8)) + "…"
    }

    /// Requests notification permission and registers with APNs (required before FCM token on real device).
    func requestAuthorizationAndRegisterForRemoteNotifications() async {
        guard Self.isFirebaseConfigured else { return }
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
}

extension PushNotificationCoordinator: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        PushDiagnostics.info("MessagingDelegate token refresh (prefix=\(PushNotificationCoordinator.tokenLogPrefix(fcmToken)))")
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
        let suppressTray = await MainActor.run {
            AppDependencies.shared.realtimeManager.isConnected
        }
        if suppressTray {
            return [.badge]
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
