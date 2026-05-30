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
            #if DEBUG
            print("[Push] GoogleService-Info.plist missing — FCM disabled (see PUSH_NOTIFICATIONS.md)")
            #endif
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    /// Call after login / session bootstrap (Android `FcmTokenRegistrar.registerCurrentTokenIfSession`).
    func registerCurrentTokenIfSession() async {
        guard Self.isFirebaseConfigured else { return }
        guard AppDependencies.shared.authSessionStore.read() != nil else { return }
        for attempt in 0..<4 {
            if let token = await Self.fetchFCMToken(), !token.isEmpty {
                await AppDependencies.shared.fcmTokenRegistrar.registerDeviceToken(token)
                return
            }
            if attempt < 3 {
                try? await Task.sleep(for: .milliseconds(400 * (attempt + 1)))
            }
        }
        #if DEBUG
        print("[Push] registerCurrentTokenIfSession: FCM token unavailable after retries (APNs / Firebase?)")
        #endif
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
            #if DEBUG
            print("[Push] notification authorization granted=\(granted)")
            #endif
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            #if DEBUG
            print("[Push] authorization request failed: \(error.localizedDescription)")
            #endif
        }
    }

    static func fetchFCMToken() async -> String? {
        await withCheckedContinuation { continuation in
            Messaging.messaging().token { token, error in
                #if DEBUG
                if let error {
                    print("[Push] FCM token fetch failed: \(error.localizedDescription)")
                }
                #endif
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
